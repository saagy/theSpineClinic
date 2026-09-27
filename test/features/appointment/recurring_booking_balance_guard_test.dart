import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_balance_diagnostics.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/recurring_pattern_picker.dart';
import 'package:spine_clinic_app/shared/widgets/doctor_select_field.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import '../../fixtures/booking_balance_harness.dart';

void main() {
  testWidgets(
    'type changes retain the chosen doctor and session billing choice',
    (tester) async {
      final assignedDoctor = bookingTestStaff.copyWith(
        id: 'doctor-assigned',
        fullName: 'Assigned Doctor',
        role: UserRole.doctor,
      );
      final selectedDoctor = assignedDoctor.copyWith(
        id: 'doctor-selected',
        fullName: 'Selected Doctor',
        isSenior: true,
      );
      await tester.pumpWidget(
        buildBookingBalanceHarness(assignedDoctors: [assignedDoctor]),
      );
      await tester.pumpAndSettle();

      final doctorField = find.byType(DoctorSelectField).first;
      final fieldState = tester.state<FormFieldState<List<Staff>>>(doctorField);
      expect(fieldState.value?.map((doctor) => doctor.id), [assignedDoctor.id]);

      fieldState.didChange([selectedDoctor]);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text(AppStrings.reassessment));
      await tester.tap(find.text(AppStrings.reassessment));
      await tester.pumpAndSettle();
      expect(fieldState.value?.map((doctor) => doctor.id), [selectedDoctor.id]);
      expect(find.text(AppStrings.assessmentDoctorReminder), findsOneWidget);

      await tester.ensureVisible(find.text(AppStrings.normalPtSession));
      await tester.tap(find.text(AppStrings.normalPtSession));
      await tester.pumpAndSettle();
      expect(fieldState.value?.map((doctor) => doctor.id), [selectedDoctor.id]);
      expect(tester.widget<Switch>(find.byType(Switch).last).value, false);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Ledger preview updates dynamically when typing recurring sessions count',
    (tester) async {
      await tester.pumpWidget(buildBookingBalanceHarness());
      await tester.pumpAndSettle();

      // Tap the 'Recurring booking' text / checkbox
      final recurringFinder = find.text('Recurring booking');
      expect(recurringFinder, findsOneWidget);
      await tester.ensureVisible(recurringFinder);
      await tester.tap(recurringFinder);
      await tester.pumpAndSettle();

      expect(find.byType(RecurringPatternPicker), findsOneWidget);

      // Select Saturday
      await tester.ensureVisible(find.text('Sat'));
      await tester.tap(find.text('Sat'));
      await tester.pumpAndSettle();

      // Enter 2 sessions (within available balance of 3)
      final sessionsInput = find.byType(TextField).last;
      await tester.enterText(sessionsInput, '2');
      await tester.pumpAndSettle();

      // Verify Live Ledger Preview shows requested count of 2
      expect(find.byType(AppointmentBalanceDiagnostics), findsOneWidget);
      expect(find.text('2'), findsWidgets);
      expect(find.text(AppStrings.projectedLeftoverMessage(1)), findsOneWidget);

      // Now enter 5 sessions (exceeding balance of 3)
      await tester.enterText(sessionsInput, '5');
      await tester.pumpAndSettle();

      // Verify Ledger Preview immediately updates with deficit
      expect(find.text(AppStrings.packageDeficitMessage(2)), findsOneWidget);
      expect(find.text(AppStrings.insufficientPackageBalance), findsOneWidget);

      // Verify Save button is disabled
      final saveButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, AppStrings.save),
      );
      expect(saveButton.onPressed, isNull);

      // Type 3 sessions (exact balance)
      await tester.enterText(sessionsInput, '3');
      await tester.pumpAndSettle();

      // Verify deficit is gone and leftover is 0
      expect(find.text(AppStrings.projectedLeftoverMessage(0)), findsOneWidget);
    },
  );

  testWidgets(
    'an unresolved booking can reach receipt reconciliation despite a balance deficit',
    (tester) async {
      await tester.pumpWidget(buildBookingBalanceHarness(pendingRetry: true));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(AppStrings.recurringBooking));
      await tester.tap(find.text(AppStrings.recurringBooking));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Sat'));
      await tester.tap(find.text('Sat'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '5');
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.insufficientPackageBalance), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, AppStrings.save),
            )
            .onPressed,
        isNotNull,
      );
    },
  );

  testWidgets(
    'Bundled assessment does not show secondary package balance toggle',
    (tester) async {
      await tester.pumpWidget(buildBookingBalanceHarness());
      await tester.pumpAndSettle();

      // Toggle bundling on
      final bundleSwitch = find.widgetWithText(
        SwitchListTile,
        AppStrings.bundleAssessmentHint,
      );
      expect(bundleSwitch, findsOneWidget);
      await tester.ensureVisible(bundleSwitch);
      await tester.tap(bundleSwitch);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.secondarySession), findsOneWidget);
      expect(
        find.text('Use package balance for secondary session'),
        findsNothing,
      );
    },
  );
}
