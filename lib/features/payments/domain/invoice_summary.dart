import 'package:freezed_annotation/freezed_annotation.dart';
import '../../patient/domain/clinic_location.dart';

part 'invoice_summary.freezed.dart';
part 'invoice_summary.g.dart';

/// Matches `invoice_register.status`.
enum InvoiceStatus {
  paid,
  partiallyPaid,
  unpaid,
  refunded,
  voided;

  static InvoiceStatus fromDb(String value) => switch (value) {
    'paid' => paid,
    'partially_paid' => partiallyPaid,
    'refunded' => refunded,
    'voided' => voided,
    _ => unpaid,
  };
}

InvoiceStatus _statusFromJson(String value) => InvoiceStatus.fromDb(value);
String _statusToJson(InvoiceStatus status) => status.name;
List<String> _doctorsFromJson(Object? value) =>
    value is List ? value.whereType<String>().toList() : const [];

/// One row of `invoice_register`: an invoice with its derived money figures.
@freezed
abstract class InvoiceSummary with _$InvoiceSummary {
  const InvoiceSummary._();

  const factory InvoiceSummary({
    required String id,
    required ClinicLocation branch,
    required int number,
    @JsonKey(name: 'patient_id') required String patientId,
    @JsonKey(name: 'invoice_date') required DateTime invoiceDate,
    @JsonKey(name: 'total_minor') required int totalMinor,
    @JsonKey(name: 'discount_minor') required int discountMinor,
    @JsonKey(name: 'value_minor') required int valueMinor,
    @JsonKey(name: 'net_collected_minor') required int collectedMinor,
    @JsonKey(name: 'due_minor') required int dueMinor,
    @JsonKey(name: 'refunded_minor') required int refundedMinor,
    @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson) required InvoiceStatus status,
    @Default('') String services,
    @JsonKey(fromJson: _doctorsFromJson) @Default([]) List<String> doctors,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'created_by_name') required String createdByName,
    required int version,
  }) = _InvoiceSummary;

  factory InvoiceSummary.fromJson(Map<String, dynamic> json) => _$InvoiceSummaryFromJson(json);

  bool get isVoided => status == InvoiceStatus.voided;

  /// Branch-prefixed document number, for example `TG-00012`.
  String get displayNumber => invoiceNumberLabel(branch, number);
}

String invoiceNumberLabel(ClinicLocation branch, int number) =>
    '${branch == ClinicLocation.tagamoa ? 'TG' : 'MG'}-${number.toString().padLeft(5, '0')}';

/// Money totals across a patient's active invoices.
class PatientInvoiceTotals {
  const PatientInvoiceTotals({required this.dueMinor, required this.collectedMinor, required this.openCount});

  factory PatientInvoiceTotals.of(Iterable<InvoiceSummary> invoices) {
    int due = 0, collected = 0, open = 0;
    for (final invoice in invoices.where((invoice) => !invoice.isVoided)) {
      due += invoice.dueMinor;
      collected += invoice.collectedMinor;
      if (invoice.dueMinor > 0) open++;
    }
    return PatientInvoiceTotals(dueMinor: due, collectedMinor: collected, openCount: open);
  }

  final int dueMinor;
  final int collectedMinor;
  final int openCount;
}
