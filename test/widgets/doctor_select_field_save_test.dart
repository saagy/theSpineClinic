import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/shared/widgets/doctor_select_field.dart';

void main() {
  testWidgets('saving preserves doctors when parent replaces its selection', (
    tester,
  ) async {
    final selected = <Staff>[
      Staff(id: 'doctor-qa', fullName: 'QA Doctor', email: 'qa@example.test',
        role: UserRole.doctor, createdAt: DateTime(2026)),
    ];
    final key = GlobalKey<FormState>();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Form(
      key: key,
      child: DoctorSelectField(initialValue: selected, onSavedDoctors: (value) {
        selected.clear();
        selected.addAll(value);
      }),
    ))));
    key.currentState!.save();
    key.currentState!.save();
    await tester.pump();
    expect(selected.map((doctor) => doctor.id), ['doctor-qa']);
    expect(find.text('QA Doctor'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
