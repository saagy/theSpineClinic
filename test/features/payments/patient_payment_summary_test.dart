import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/features/payments/domain/patient_payment_summary.dart';
import 'package:spine_clinic_app/features/payments/domain/payment_record.dart';

void main() {
  test('due total excludes fully paid and overpaid records without cancelling other debts', () {
    PaymentRecord record(String id, double amount, double? total) => PaymentRecord(
      id: id,
      patientId: 'patient',
      amount: amount,
      totalPrice: total,
      reason: 'Service',
      recordedAt: DateTime(2026),
    );
    final summary = PatientPaymentSummary([
      record('partial', 1200, 1800),
      record('full', 600, null),
      record('over', 200, 100),
      record('unpaid', 0, 300),
    ]);
    expect(summary.totalDue, 900);
    expect(summary.totalPaid, 2000);
    expect(summary.outstanding.map((p) => p.id), ['partial', 'unpaid']);
  });
}
