import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/appointment/presentation/booking_patient_search_provider.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/patient_search_sheet.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';

void main() {
  final testPatients = [
    Patient(
      id: 'patient-1',
      fullName: 'Amr Diab',
      phoneNumber: '01000000001',
      clinic: ClinicLocation.tagamoa,
      createdAt: DateTime(2026),
    ),
    Patient(
      id: 'patient-2',
      fullName: 'Mona Zaki',
      phoneNumber: '01000000002',
      clinic: ClinicLocation.masrElgedida,
      createdAt: DateTime(2026),
    ),
  ];

  testWidgets('renders PatientSearchSheet and displays bounded initial patient list', (tester) async {
    Patient? selectedPatient;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingPatientSearchProvider('').overrideWith((ref) async => testPatients),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: PatientSearchSheet(
              onSelected: (p) => selectedPatient = p,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.selectPatient), findsOneWidget);
    expect(find.text(AppStrings.searchPatientHint), findsOneWidget);
    expect(find.text('Amr Diab'), findsOneWidget);
    expect(find.text('Mona Zaki'), findsOneWidget);

    await tester.tap(find.text('Amr Diab'));
    await tester.pump();

    expect(selectedPatient, equals(testPatients.first));
  });

  testWidgets('displays noPatientsFound when search results are empty', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingPatientSearchProvider('').overrideWith((ref) async => const <Patient>[]),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: PatientSearchSheet(
              onSelected: _noop,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.noPatientsFound), findsOneWidget);
  });
}

void _noop(Patient p) {}
