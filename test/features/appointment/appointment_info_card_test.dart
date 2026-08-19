import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_info_card.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_linked_session_row.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  final testAppt = Appointment(
    id: 'appt-1',
    patientId: 'patient-1',
    type: AppointmentType.normalPtSession,
    scheduledAt: DateTime(2026, 8, 20, 10, 30),
    status: AppointmentStatus.scheduled,
    usePackage: true,
    createdBy: 'staff-1',
    createdAt: DateTime(2026, 8, 1),
  );

  final linkedAppt = Appointment(
    id: 'appt-2',
    patientId: 'patient-1',
    type: AppointmentType.initialAssessment,
    scheduledAt: DateTime(2026, 8, 20, 11, 0),
    status: AppointmentStatus.scheduled,
    usePackage: false,
    createdBy: 'staff-1',
    createdAt: DateTime(2026, 8, 1),
  );

  testWidgets('renders schedule data and using package indicator', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AppointmentInfoCard(appointment: testAppt),
          ),
        ),
      ),
    );

    expect(find.text(AppStrings.date.toUpperCase()), findsOneWidget);
    expect(find.text(AppStrings.time.toUpperCase()), findsOneWidget);
    expect(find.text(AppStrings.visitType.toUpperCase()), findsOneWidget);
    expect(find.text(AppStrings.packageStatus.toUpperCase()), findsOneWidget);
    expect(find.text(AppStrings.usingPackage), findsOneWidget);
    expect(find.byType(AppointmentLinkedSessionRow), findsNothing);
  });

  testWidgets('renders linked sessions cleanly when provided', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AppointmentInfoCard(
                appointment: testAppt,
                linkedAppointments: [linkedAppt],
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      find.text(AppStrings.linkedSession.toUpperCase()),
      findsOneWidget,
    );
    expect(find.byType(AppointmentLinkedSessionRow), findsOneWidget);
    expect(find.text(linkedAppt.type.displayLabel), findsOneWidget);
  });
}
