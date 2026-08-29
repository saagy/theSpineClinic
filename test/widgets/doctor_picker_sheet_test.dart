import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';
import 'package:spine_clinic_app/shared/widgets/doctor_picker_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/doctor_picker_tile.dart';

void main() {
  final List<Staff> doctors = [
    _doctor('a', 'Dr Alice', true),
    _doctor('b', 'Dr Bob', true),
    _doctor('c', 'Dr Carol', false),
  ];

  testWidgets('DoctorPickerTile renders name and active/deactivated badge', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DoctorPickerTile(
            doctor: doctors[2],
            isSelected: false,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Dr Carol'), findsOneWidget);
    expect(find.text(AppStrings.deactivated), findsOneWidget);
  });

  testWidgets('DoctorPickerSheet multi-select accumulates selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allDoctorsForFilterProvider.overrideWith((ref) => Future.value(doctors)),
          activeDoctorsProvider.overrideWith((ref) => Future.value(doctors.where((d) => d.isActive).toList())),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: DoctorPickerSheet(
              selectedDoctorIds: {},
              isMultiSelect: true,
              showDeactivated: true,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Dr Alice'), findsOneWidget);
    expect(find.text('Dr Bob'), findsOneWidget);
    expect(find.text('Dr Carol'), findsOneWidget);

    // Tap Alice
    await tester.tap(find.text('Dr Alice'));
    await tester.pump();

    // Tap Bob
    await tester.tap(find.text('Dr Bob'));
    await tester.pump();

    expect(find.byIcon(Icons.check_rounded), findsNWidgets(2));
  });

  testWidgets('DoctorPickerSheet search filters doctors', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allDoctorsForFilterProvider.overrideWith((ref) => Future.value(doctors)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: DoctorPickerSheet(
              selectedDoctorIds: {},
              isMultiSelect: true,
              showDeactivated: true,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Bob');
    await tester.pump();

    expect(find.text('Dr Bob'), findsOneWidget);
    expect(find.text('Dr Alice'), findsNothing);
  });
}

Staff _doctor(String id, String name, bool isActive) => Staff(
  id: id,
  fullName: name,
  email: '$id@clinic.test',
  role: UserRole.doctor,
  isActive: isActive,
  deactivatedAt: isActive ? null : DateTime(2026),
  createdAt: DateTime(2026),
);
