import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_medical_history.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/medical_history_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/edit_medical_history_sheet.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/medical_history_section.dart';

class _StaticCurrentUser extends CurrentUser {
  _StaticCurrentUser(this._user);
  final Staff? _user;

  @override
  Future<Staff?> build() async => _user;
}

class _StaticMedicalHistoryNotifier extends PatientMedicalHistoryNotifier {
  _StaticMedicalHistoryNotifier(this._history);
  final PatientMedicalHistory? _history;

  @override
  Future<PatientMedicalHistory?> build(String patientId) async => _history;
}

void main() {
  final seniorDoctor = Staff(
    id: 'staff-senior-1',
    fullName: 'Dr. Senior',
    email: 'senior@spineclinic.com',
    role: UserRole.doctor,
    isSenior: true,
    createdAt: DateTime(2026, 1, 1),
  );

  final juniorDoctor = Staff(
    id: 'staff-junior-1',
    fullName: 'Dr. Junior',
    email: 'junior@spineclinic.com',
    role: UserRole.doctor,
    isSenior: false,
    createdAt: DateTime(2026, 1, 1),
  );

  final sampleHistory = PatientMedicalHistory(
    id: 'history-1',
    patientId: 'patient-1',
    hasDiabetes: true,
    hba1cValue: '7.2%',
    hasHypertension: true,
    hasHyperlipidemia: false,
    hasRheumatology: true,
    rheumatologyDetails: 'Rheumatoid Arthritis in wrists',
    additionalNotes: 'Patient taking regular medication',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  testWidgets('MedicalHistorySection displays empty state when no history exists', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith(() => _StaticCurrentUser(juniorDoctor)),
          patientMedicalHistoryProvider('patient-1').overrideWith(
            () => _StaticMedicalHistoryNotifier(null),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: MedicalHistorySection(patientId: 'patient-1'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text(AppStrings.medicalHistory.toUpperCase()), findsOneWidget);
    expect(find.text(AppStrings.noMedicalHistoryRecorded), findsOneWidget);
    // Junior doctor should not see Edit / Add button
    expect(find.text(AppStrings.add), findsNothing);
    expect(find.text(AppStrings.edit), findsNothing);
  });

  testWidgets('MedicalHistorySection displays Add button for senior doctor when empty', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith(() => _StaticCurrentUser(seniorDoctor)),
          patientMedicalHistoryProvider('patient-1').overrideWith(
            () => _StaticMedicalHistoryNotifier(null),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: MedicalHistorySection(patientId: 'patient-1'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text(AppStrings.add), findsOneWidget);
  });

  testWidgets('MedicalHistorySection displays all recorded conditions properly', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith(() => _StaticCurrentUser(seniorDoctor)),
          patientMedicalHistoryProvider('patient-1').overrideWith(
            () => _StaticMedicalHistoryNotifier(sampleHistory),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: MedicalHistorySection(patientId: 'patient-1'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Check conditions
    expect(find.text('${AppStrings.diabetes} (${AppStrings.hba1c}: 7.2%)'), findsOneWidget);
    expect(find.text(AppStrings.hypertension), findsOneWidget);
    expect(find.text('${AppStrings.rheumatology}: Rheumatoid Arthritis in wrists'), findsOneWidget);
    expect(find.text('Patient taking regular medication'), findsOneWidget);
    // Senior doctor should see Edit button
    expect(find.text(AppStrings.edit), findsOneWidget);
  });

  testWidgets('EditMedicalHistorySheet renders all condition controls', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith(() => _StaticCurrentUser(seniorDoctor)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: EditMedicalHistorySheet(
              patientId: 'patient-1',
              initialHistory: null,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text(AppStrings.diabetes), findsOneWidget);
    expect(find.text(AppStrings.hypertension), findsOneWidget);
    expect(find.text(AppStrings.hyperlipidemia), findsOneWidget);
    expect(find.text(AppStrings.rheumatology), findsOneWidget);
    expect(find.text(AppStrings.save), findsOneWidget);
  });

  testWidgets('MedicalHistorySection updates in place immediately when updateData is called', (tester) async {
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith(() => _StaticCurrentUser(seniorDoctor)),
        patientMedicalHistoryProvider('patient-1').overrideWith(
          () => _StaticMedicalHistoryNotifier(null),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: MedicalHistorySection(patientId: 'patient-1'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text(AppStrings.noMedicalHistoryRecorded), findsOneWidget);

    // Call updateData in-place
    container
        .read(patientMedicalHistoryProvider('patient-1').notifier)
        .updateData(sampleHistory);

    await tester.pump();

    // Immediately shows conditions in place
    expect(find.text('${AppStrings.diabetes} (${AppStrings.hba1c}: 7.2%)'), findsOneWidget);
    expect(find.text(AppStrings.noMedicalHistoryRecorded), findsNothing);
  });
}
