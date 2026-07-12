import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_detail_header.dart';

void main() {
  testWidgets('patient header remains tappable without a date window', (
    WidgetTester tester,
  ) async {
    final Patient patient = Patient(
      id: 'patient-1',
      fullName: 'Test Patient',
      phoneNumber: '01000000000',
      clinic: ClinicLocation.tagamoa,
      createdAt: DateTime(2026),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AppointmentDetailHeader(patient: patient)),
      ),
    );

    final InkWell link = tester.widget<InkWell>(find.byType(InkWell));
    expect(link.onTap, isNotNull);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
  });
}
