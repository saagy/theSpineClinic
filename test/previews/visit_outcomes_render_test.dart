import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_palette.dart';
import 'package:spine_clinic_app/core/constants/app_theme.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_event.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_action_buttons.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_history_section.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_status_banner.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import '../fixtures/workspace_harness.dart';
import '../fixtures/workspace_overrides.dart';
import 'ui_polish_capture.dart';

/// The visit history, a missed visit and an earlier day's locked outcome, and
/// the balance correction on the Payments tab, at phone and desktop sizes.
/// Pass `--dart-define=UI_POLISH_CAPTURE=dir` to save PNGs for review.
void main() {
  setUpAll(loadPolishFonts);
  final DateTime day = DateTime.now().subtract(const Duration(days: 3));
  final events = [
    AppointmentEvent(kind: AppointmentEventKind.booked, at: day.subtract(const Duration(days: 4)),
        toStatus: AppointmentStatus.scheduled, actorName: 'Salma Mostafa'),
    AppointmentEvent(kind: AppointmentEventKind.status, at: day, fromStatus: AppointmentStatus.scheduled,
        toStatus: AppointmentStatus.checkedIn, actorName: 'Salma Mostafa'),
    AppointmentEvent(kind: AppointmentEventKind.status, at: day.add(const Duration(hours: 2)),
        fromStatus: AppointmentStatus.checkedIn, toStatus: AppointmentStatus.noShow,
        actorName: 'Nour Mahmoud', reason: 'Checked in on the wrong patient'),
  ];
  final visit = Appointment(id: 'visit', patientId: 'patient', type: AppointmentType.normalPtSession,
      scheduledAt: day, status: AppointmentStatus.noShow, createdAt: day, statusChangedAt: day);

  for (final (name, width, dark) in <(String, double, bool)>[('phone', 390, false), ('desktop', 1280, true)]) {
    testWidgets('visit history and locked outcome render on $name', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: ProviderScope(
          overrides: [
            currentUserProvider.overrideWith(() => WorkspaceUser('reception')),
            appointmentEventsProvider('visit').overrideWith((ref) async => events),
          ],
          child: MaterialApp(
            theme: AppTheme.light(clinicalBluePaletteLight),
            darkTheme: AppTheme.dark(clinicalBluePaletteDark),
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
            home: Scaffold(
              body: ListView(children: [
                AppointmentStatusBanner(status: visit.status, scheduledAt: visit.scheduledAt),
                const AppointmentHistorySection(appointmentId: 'visit'),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: AppointmentActionButtons(appointment: visit, userRole: UserRole.receptionist),
                ),
              ]),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.visit.eventNoShow), findsOneWidget);
      expect(find.text(AppStrings.visit.eventReason('Checked in on the wrong patient')), findsOneWidget);
      expect(find.text(AppStrings.visit.lockedForDesk), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capturePolish(tester, key, 'visit-history-$name');
    });

    testWidgets('balance correction renders on $name', (tester) async {
      tester.view.physicalSize = Size(width, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: WorkspaceHarness(role: 'reception-payments', dark: dark),
      ));
      await tester.pumpAndSettle();
      final tab = find.text(AppStrings.payments).first;
      await tester.ensureVisible(tab);
      await tester.tap(tab);
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.balances.history), findsOneWidget);
      await capturePolish(tester, key, 'balance-tab-$name');
      await tester.ensureVisible(find.text(AppStrings.balances.adjust));
      await tester.tap(find.text(AppStrings.balances.adjust));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capturePolish(tester, key, 'balance-dialog-$name');
    });
  }
}
