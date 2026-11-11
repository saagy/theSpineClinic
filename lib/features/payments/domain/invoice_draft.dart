import '../../patient/domain/clinic_location.dart';
import 'service_catalog_item.dart';

enum DiscountKind { none, percent, amount }

/// One service on a new invoice.
class InvoiceLineDraft {
  const InvoiceLineDraft({required this.service, this.quantity = 1, this.doctorIds = const []});
  final ServiceCatalogItem service;
  final int quantity;
  final List<String> doctorIds;

  int get grossMinor => service.priceMinor * quantity;
  int get sessions => service.type.usesSessions ? service.sessionsPerUnit * quantity : 0;

  InvoiceLineDraft copyWith({int? quantity, List<String>? doctorIds}) => InvoiceLineDraft(
    service: service,
    quantity: quantity ?? this.quantity,
    doctorIds: doctorIds ?? this.doctorIds,
  );

  Map<String, Object?> toPayload() => {
    'service_id': service.id,
    'quantity': quantity,
    'unit_price_minor': service.priceMinor,
    'doctor_ids': service.creditsDoctors ? doctorIds : const <String>[],
  };
}

/// A complete `invoice_create` command, with the same arithmetic the
/// database uses so the on-screen summary matches the issued invoice.
class InvoiceDraft {
  const InvoiceDraft({
    required this.patientId,
    required this.branch,
    required this.invoiceDate,
    required this.lines,
    this.discountKind = DiscountKind.none,
    this.discountValue = 0,
    this.cashMinor = 0,
    this.visaMinor = 0,
    this.note = '',
  });

  final String patientId;
  final ClinicLocation branch;
  final DateTime invoiceDate;
  final List<InvoiceLineDraft> lines;
  final DiscountKind discountKind;

  /// Basis points (10000 = 100%) for percent discounts, piasters for amounts.
  final int discountValue;
  final int cashMinor;
  final int visaMinor;
  final String note;

  int get subtotalMinor => lines.fold(0, (sum, line) => sum + line.grossMinor);

  /// Percent discounts round half up, matching PostgreSQL `round()`.
  int get discountMinor => switch (discountKind) {
    DiscountKind.none => 0,
    DiscountKind.percent => ((subtotalMinor * discountValue + 5000) ~/ 10000),
    DiscountKind.amount => discountValue,
  };

  int get totalMinor => subtotalMinor - discountMinor;
  int get paidNowMinor => cashMinor + visaMinor;
  int get dueAfterMinor => totalMinor - paidNowMinor;
  bool get hasDiscount => discountKind != DiscountKind.none;

  int sessionsOf(ServiceType type) => lines
      .where((line) => line.service.type == type)
      .fold(0, (sum, line) => sum + line.sessions);

  Map<String, Object?> toPayload() => {
    'patient_id': patientId,
    'branch': branch.dbValue,
    'invoice_date': _date(invoiceDate),
    'lines': [for (final line in lines) line.toPayload()],
    'discount': {'kind': discountKind.name, 'value': hasDiscount ? discountValue : 0},
    'payments': [
      if (cashMinor > 0) {'method': 'cash', 'amount_minor': cashMinor},
      if (visaMinor > 0) {'method': 'visa', 'amount_minor': visaMinor},
    ],
    if (note.trim().isNotEmpty) 'note': note.trim(),
  };

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
