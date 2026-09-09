import 'package:spine_clinic_app/features/payments/domain/payment_record.dart';

/// Patient-level payment totals; clinical programs do not own these balances.
class PatientPaymentSummary {
  PatientPaymentSummary(List<PaymentRecord> records)
    : totalPaid = records.fold(0, (sum, record) => sum + record.amount),
      totalDue = records.fold(0, (sum, record) => sum + record.remainingDue),
      outstanding = List.unmodifiable(records.where((r) => r.hasOutstandingDue));
  final double totalPaid;
  final double totalDue;
  final List<PaymentRecord> outstanding;
}
