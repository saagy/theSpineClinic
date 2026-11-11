import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/payments/domain/invoice_summary.dart';

InvoiceSummary sampleInvoice(
  int number,
  String services, {
  required int total,
  int paid = 0,
  int refunded = 0,
  InvoiceStatus? status,
  List<String> doctors = const ['Dr. Ahmed Hassan'],
  ClinicLocation branch = ClinicLocation.tagamoa,
  int daysAgo = 0,
}) {
  final int value = total - refunded;
  final bool voided = status == InvoiceStatus.voided;
  final int due = voided ? 0 : value - paid;
  return InvoiceSummary(
    id: 'invoice-$number',
    branch: branch,
    number: number,
    patientId: 'patient-fixture',
    invoiceDate: DateTime(2026, 11, 10).subtract(Duration(days: daysAgo)),
    totalMinor: total,
    discountMinor: 0,
    valueMinor: value,
    collectedMinor: paid,
    dueMinor: due,
    refundedMinor: refunded,
    status: status ??
        (due == 0 ? (refunded > 0 ? InvoiceStatus.refunded : InvoiceStatus.paid)
            : paid > 0 ? InvoiceStatus.partiallyPaid : InvoiceStatus.unpaid),
    services: services,
    doctors: doctors,
    createdAt: DateTime(2026, 11, 10),
    createdByName: 'Nour Mahmoud',
    version: 1,
  );
}

final sampleInvoices = [
  sampleInvoice(42, '6 PT sessions, Initial assessment', total: 300000, paid: 100000),
  sampleInvoice(37, '6 spinal traction sessions', total: 135000, paid: 135000, doctors: const [], daysAgo: 6),
  sampleInvoice(31, '12 PT sessions', total: 450000, paid: 270000, refunded: 180000,
      doctors: const ['Dr. Ahmed Hassan', 'Dr. Salma Ibrahim'], daysAgo: 20),
  sampleInvoice(29, 'Shockwave therapy session for chronic plantar fasciitis', total: 70000,
      status: InvoiceStatus.voided, branch: ClinicLocation.masrElgedida, daysAgo: 24),
];
