import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/agenda_status_controller.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_agenda_menu.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import '../../fixtures/workspace_overrides.dart';

class _StatusMutation extends AgendaStatusController {
  AppointmentStatus? requested;
  @override
  Future<Result<void>?> update(String patientId, AppointmentStatus status) async {
    requested = status;
    return const Success<void>(null);
  }
}

void main() {
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
                    appointmentId: 'appointment',
                    patientId: 'patient',
                    status: status,
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
