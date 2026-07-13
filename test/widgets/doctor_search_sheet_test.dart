import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/doctor_search_sheet.dart';

void main() {
  final List<Staff> doctors = [
    _doctor('a', 'Dr Alice'),
    _doctor('b', 'Dr Bob'),
    _doctor('c', 'Dr Carol'),
  ];

  testWidgets('doctor sheet accumulates and emits multi-selection', (
    tester,
  ) async {
    List<Staff> selected = const [];
    await tester.pumpWidget(_harness(doctors, (value) => selected = value));

    await tester.tap(find.text('Dr Alice'));
    await tester.pump();
    await tester.tap(find.text('Dr Bob'));
    await tester.pump();

    expect(selected.map((doctor) => doctor.id), ['a', 'b']);
    expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(2));
  });

  testWidgets('doctor sheet removes one doctor while preserving another', (
    tester,
  ) async {
    List<Staff> selected = const [];
    await tester.pumpWidget(_harness(doctors, (value) => selected = value));

    await tester.tap(find.text('Dr Alice'));
    await tester.tap(find.text('Dr Bob'));
    await tester.pump();
    await tester.tap(find.text('Dr Alice'));
    await tester.pump();

    expect(selected.map((doctor) => doctor.id), ['b']);
  });

  testWidgets('doctor sheet prevents removing the final doctor', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(doctors, (_) {}));

    await tester.tap(find.text('Dr Alice'));
    await tester.pump();
    await tester.tap(find.text('Dr Alice'));
    await tester.pump();

    expect(find.text(AppStrings.atLeastOneDoctorRequired), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });
}

Widget _harness(List<Staff> doctors, ValueChanged<List<Staff>> onChanged) {
  return MaterialApp(
    home: Scaffold(
      body: DoctorSearchSheet(
        activeDoctors: doctors,
        selectedDoctors: const [],
        onSelectionChanged: onChanged,
      ),
    ),
  );
}

Staff _doctor(String id, String name) => Staff(
  id: id,
  fullName: name,
  email: '$id@clinic.test',
  role: UserRole.doctor,
  createdAt: DateTime(2026),
);
