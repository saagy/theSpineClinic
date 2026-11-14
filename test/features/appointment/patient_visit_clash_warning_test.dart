import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/patient_visit_clash_warning.dart';
import '../../fixtures/booking_balance_harness.dart';

const _s = AppStrings.bookingClash;

// The harness books 1 Sep 2026 at 9:00 AM.
Appointment _visit(DateTime at, {AppointmentStatus status = AppointmentStatus.scheduled}) =>
    Appointment(
      id: 'existing-${at.hour}',
      patientId: bookingTestPatientId,
      type: AppointmentType.reassessment,
      scheduledAt: at.toUtc(),
      status: status,
      createdAt: DateTime(2026),
    );

void main() {
  testWidgets('warns when the patient is booked at the same time', (tester) async {
    await tester.pumpWidget(
      buildBookingBalanceHarness(existingVisits: [_visit(DateTime(2026, 9, 1, 9))]),
    );
    await tester.pumpAndSettle();

    expect(find.text(_s.sameTime), findsOneWidget);
    expect(find.textContaining('Same time: '), findsOneWidget);
    expect(find.text(_s.note), findsOneWidget);
    // Advice only: Save stays available.
    final save = tester.widget<FilledButton>(find.widgetWithText(FilledButton, AppStrings.save));
    expect(save.onPressed, isNotNull);
  });

  testWidgets('warns about another visit that day', (tester) async {
    await tester.pumpWidget(
      buildBookingBalanceHarness(existingVisits: [_visit(DateTime(2026, 9, 1, 14))]),
    );
    await tester.pumpAndSettle();
    expect(find.text(_s.sameDay), findsOneWidget);
  });

  testWidgets('stays silent without a clash', (tester) async {
    await tester.pumpWidget(
      buildBookingBalanceHarness(
        existingVisits: [
          _visit(DateTime(2026, 9, 2, 9)),
          _visit(DateTime(2026, 9, 1, 9), status: AppointmentStatus.cancelled),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PatientVisitClashWarning), findsOneWidget);
    expect(find.text(_s.note), findsNothing);
  });
}
