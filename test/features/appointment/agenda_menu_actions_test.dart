import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/agenda_status_controller.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_agenda_menu.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import '../../fixtures/workspace_overrides.dart';

class _StatusMutation extends AgendaStatusController {
  AppointmentStatus? requested;
  String? reason;
  @override
  Future<Result<void>?> update(String patientId, AppointmentStatus status, {String? reason}) async {
    requested = status;
    this.reason = reason;
    return const Success<void>(null);
  }
}

Appointment _visit(AppointmentStatus status, DateTime day) => Appointment(
  id: 'appointment',
  patientId: 'patient',
  type: AppointmentType.normalPtSession,
  scheduledAt: day,
  status: status,
  createdAt: day,
  statusChangedAt: day,
);

Future<_StatusMutation> _openMenu(WidgetTester tester, String role, Appointment visit) async {
  final mutation = _StatusMutation();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWith(() => WorkspaceUser(role)),
        agendaStatusControllerProvider('appointment').overrideWith(() => mutation),
      ],
      child: MaterialApp(
        home: Scaffold(body: Center(child: AppointmentAgendaMenu(appointment: visit, patientId: 'patient'))),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip(AppStrings.moreActions));
  await tester.pumpAndSettle();
  return mutation;
}

void main() {
  testWidgets('a visit due today can be marked as a no-show; a later one cannot', (tester) async {
    final mutation = await _openMenu(tester, 'reception', _visit(AppointmentStatus.scheduled, DateTime.now()));
    await tester.tap(find.text(AppStrings.visit.markNoShow));
    await tester.pumpAndSettle();
    expect(mutation.requested, AppointmentStatus.noShow);
    await _openMenu(
      tester,
      'reception',
      _visit(AppointmentStatus.scheduled, DateTime.now().add(const Duration(days: 2))),
    );
    expect(find.text(AppStrings.visit.markNoShow), findsNothing);
  });

  testWidgets("the front desk cannot change an earlier day's check-in", (tester) async {
    final DateTime earlier = DateTime.now().subtract(const Duration(days: 3));
    await _openMenu(tester, 'reception', _visit(AppointmentStatus.checkedIn, earlier));
    expect(find.text(AppStrings.undoCheckIn), findsNothing);
    expect(find.text(AppStrings.cancelAppointment), findsNothing);
    expect(find.text(AppStrings.patientDetails), findsOneWidget);
  });

  testWidgets("payment staff change an earlier day's check-in with a reason", (tester) async {
    final DateTime earlier = DateTime.now().subtract(const Duration(days: 3));
    final mutation = await _openMenu(tester, 'reception-payments', _visit(AppointmentStatus.checkedIn, earlier));
    await tester.tap(find.text(AppStrings.undoCheckIn));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.visit.reasonTitle), findsOneWidget);
    await tester.tap(find.text(AppStrings.visit.saveChange));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.visit.reasonRequired), findsOneWidget);
    expect(mutation.requested, isNull);
    await tester.enterText(find.byType(TextFormField), '  Wrong patient ');
    await tester.tap(find.text(AppStrings.visit.saveChange));
    await tester.pumpAndSettle();
    expect(mutation.requested, AppointmentStatus.scheduled);
    expect(mutation.reason, 'Wrong patient');
  });

  for (final status in AppointmentStatus.values) {
    testWidgets('menu leads with permitted action for $status without a page refresh', (tester) async {
      final mutation = _StatusMutation();
      int rowTaps = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith(() => WorkspaceUser('reception')),
            agendaStatusControllerProvider('appointment').overrideWith(() => mutation),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: GestureDetector(
                onTap: () => rowTaps++,
                child: Center(
                  child: AppointmentAgendaMenu(
                    appointment: _visit(status, DateTime.now()),
                    patientId: 'patient',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(AppStrings.moreActions));
      await tester.pumpAndSettle();
      final label = switch (status) {
        AppointmentStatus.scheduled => AppStrings.checkIn,
        AppointmentStatus.checkedIn => AppStrings.undoCheckIn,
        AppointmentStatus.cancelled => AppStrings.restoreAppointment,
        AppointmentStatus.noShow => AppStrings.visit.undoNoShow,
      };
      expect(
        tester.getTopLeft(find.text(label)).dy,
        lessThan(tester.getTopLeft(find.text(AppStrings.patientDetails)).dy),
      );
      expect(find.text(AppStrings.viewDetails), findsNothing);
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(
        mutation.requested,
        status == AppointmentStatus.scheduled
            ? AppointmentStatus.checkedIn
            : AppointmentStatus.scheduled,
      );
      expect(rowTaps, 0);
      expect(tester.takeException(), isNull);
    });
  }
}
