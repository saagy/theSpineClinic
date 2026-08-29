import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_balance_diagnostics.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/new_appointment_form.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/recurring_pattern_picker.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';

class _FakeAppointmentRepo implements AppointmentRepository {
  @override
  Future<Result<List<Staff>>> getAssignedDoctors(String patientId) async =>
      const Result.success([]);

  @override
  Future<Result<int>> getFutureScheduledAppointmentsCountForType({
    required String patientId,
    required AppointmentType type,
  }) async =>
      const Result.success(0);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestCurrentUser extends CurrentUser {
  _TestCurrentUser(this.staff);
  final Staff staff;

  @override
  Future<Staff?> build() async => staff;
}

final _testPatient = Patient(
  id: '11111111-1111-1111-1111-111111111111',
  fullName: 'Test Patient',
  phoneNumber: '07700000000',
  sessionBalance: 3,
  tractionBalance: 2,
  clinic: ClinicLocation.tagamoa,
  createdAt: DateTime(2026),
);

final _testStaff = Staff(
  id: '22222222-2222-2222-2222-222222222222',
  fullName: 'Receptionist User',
  email: 'receptionist@spine.com',
  role: UserRole.receptionist,
  isActive: true,
  createdAt: DateTime(2026),
);

Widget _buildTestWidget() {
  return ProviderScope(
    overrides: [
      appointmentRepositoryProvider.overrideWithValue(_FakeAppointmentRepo()),
      patientDetailProvider(_testPatient.id)
          .overrideWith((ref) => Future.value(_testPatient)),
      currentUserProvider.overrideWith(() => _TestCurrentUser(_testStaff)),
      availableBalanceForTypeProvider((
        patientId: _testPatient.id,
        type: AppointmentType.normalPtSession,
      )).overrideWith((ref) => Future.value(3)),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: NewAppointmentForm(
          preselectedPatientId: _testPatient.id,
          preselectedDate: DateTime(2026, 9, 1),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'Ledger preview updates dynamically when typing recurring sessions count',
    (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      // Tap the 'Recurring booking' text / checkbox
      final recurringFinder = find.text('Recurring booking');
      expect(recurringFinder, findsOneWidget);
      await tester.tap(recurringFinder);
      await tester.pumpAndSettle();

      expect(find.byType(RecurringPatternPicker), findsOneWidget);

      // Select Saturday
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
      final saveButton = tester.widget<AppButton>(find.byType(AppButton));
      expect(saveButton.onPressed, isNull);

      // Type 3 sessions (exact balance)
      await tester.enterText(sessionsInput, '3');
      await tester.pumpAndSettle();

      // Verify deficit is gone and leftover is 0
      expect(find.text(AppStrings.projectedLeftoverMessage(0)), findsOneWidget);
    },
  );

  testWidgets(
    'Bundled assessment does not show secondary package balance toggle',
    (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      // Toggle bundling on
      final bundleSwitch = find.widgetWithText(
        SwitchListTile,
        'Bundle with assessment',
      );
      expect(bundleSwitch, findsOneWidget);
      await tester.tap(bundleSwitch);
      await tester.pumpAndSettle();

      expect(find.text('Secondary Session Settings'), findsOneWidget);
      expect(
        find.text('Use package balance for secondary session'),
        findsNothing,
      );
    },
  );
}
