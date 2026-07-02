import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/features/payments/domain/payment_record.dart';

void main() {
  group('PaymentRecord Model Tests', () {
    test('remainingDue and hasOutstandingDue calculate correctly', () {
      final now = DateTime.now();

      // Case 1: Paid in full (totalPrice is null)
      final record1 = PaymentRecord(
        id: '1',
        patientId: 'pat_1',
        amount: 500.0,
        reason: 'PT Session',
        recordedAt: now,
      );
      expect(record1.totalPrice, isNull);
      expect(record1.remainingDue, 0.0);
      expect(record1.hasOutstandingDue, isFalse);

      // Case 2: Paid in full (totalPrice equals amount)
      final record2 = PaymentRecord(
        id: '2',
        patientId: 'pat_1',
        amount: 500.0,
        reason: 'PT Session',
        recordedAt: now,
        totalPrice: 500.0,
      );
      expect(record2.remainingDue, 0.0);
      expect(record2.hasOutstandingDue, isFalse);

      // Case 3: Partial payment (totalPrice > amount)
      final record3 = PaymentRecord(
        id: '3',
        patientId: 'pat_1',
        amount: 1000.0,
        reason: 'Package (6 Sessions)',
        recordedAt: now,
        totalPrice: 2000.0,
      );
      expect(record3.remainingDue, 1000.0);
      expect(record3.hasOutstandingDue, isTrue);

      // Case 4: Invalid edge case where amount > totalPrice (treated as no due)
      final record4 = PaymentRecord(
        id: '4',
        patientId: 'pat_1',
        amount: 1200.0,
        reason: 'Package (6 Sessions)',
        recordedAt: now,
        totalPrice: 1000.0,
      );
      expect(record4.remainingDue, 0.0);
      expect(record4.hasOutstandingDue, isFalse);
    });

    test('JSON serialization and deserialization works correctly', () {
      final now = DateTime.parse('2026-07-02T00:00:00.000Z');
      final json = {
        'id': 'test_id',
        'patient_id': 'pat_1',
        'amount': 1000.0,
        'reason': 'Package (6 Sessions)',
        'recorded_by': 'staff_1',
        'recorded_at': '2026-07-02T00:00:00.000Z',
        'session_balance_added': 6,
        'traction_balance_added': 0,
        'total_price': 2500.0,
      };

      final record = PaymentRecord.fromJson(json);

      expect(record.id, 'test_id');
      expect(record.patientId, 'pat_1');
      expect(record.amount, 1000.0);
      expect(record.reason, 'Package (6 Sessions)');
      expect(record.recordedBy, 'staff_1');
      expect(record.recordedAt, now);
      expect(record.sessionBalanceAdded, 6);
      expect(record.tractionBalanceAdded, 0);
      expect(record.totalPrice, 2500.0);
      expect(record.remainingDue, 1500.0);
      expect(record.hasOutstandingDue, isTrue);

      // Verify toJson() includes the new column
      final serialized = record.toJson();
      expect(serialized['total_price'], 2500.0);
      expect(serialized['amount'], 1000.0);
    });
  });
}
