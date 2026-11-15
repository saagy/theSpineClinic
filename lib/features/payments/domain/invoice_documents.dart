import '../../patient/domain/clinic_location.dart';
import 'invoice_summary.dart';

/// Matches the `method` and `payback_method` columns.
enum PaymentMethod {
  cash,
  visa;

  static PaymentMethod fromDb(String value) => value == 'visa' ? visa : cash;
}

ClinicLocation _branch(Object? value) =>
    ClinicLocation.values.firstWhere((branch) => branch.dbValue == value);

DateTime _time(Object? value) => DateTime.parse(value! as String);

/// Whether money was taken on a day before today (device time). Changing
/// it then changes a day that has already been reported.
bool takenBeforeToday(DateTime receivedAt, {DateTime? now}) {
  final DateTime local = receivedAt.toLocal();
  final DateTime today = now ?? DateTime.now();
  return DateTime(local.year, local.month, local.day).isBefore(DateTime(today.year, today.month, today.day));
}

/// Who voided a document, when and why. Voided documents stay on record.
class VoidStamp {
  const VoidStamp({required this.at, required this.byName, required this.reason});

  /// Null while the document is active.
  static VoidStamp? fromJson(Map<String, dynamic> json) => json['voided_at'] == null
      ? null
      : VoidStamp(
          at: _time(json['voided_at']),
          byName: json['voided_by_name'] as String? ?? '',
          reason: json['void_reason'] as String? ?? '',
        );

  final DateTime at;
  final String byName;
  final String reason;
}

/// A link to the invoice this one corrects, or to its correction.
class InvoiceRef {
  const InvoiceRef({required this.id, required this.branch, required this.number});

  static InvoiceRef? fromJson(Map<String, dynamic>? json) => json == null
      ? null
      : InvoiceRef(
          id: json['id'] as String,
          branch: _branch(json['branch']),
          number: (json['number'] as num).toInt(),
        );

  final String id;
  final ClinicLocation branch;
  final int number;

  String get displayNumber => invoiceNumberLabel(branch, number);
}

/// Money received against an invoice.
class InvoiceReceipt {
  const InvoiceReceipt({
    required this.id,
    required this.branch,
    required this.number,
    required this.amountMinor,
    required this.method,
    required this.receivedAt,
    required this.recordedAt,
    required this.recordedByName,
    this.replacesReceiptId,
    this.voided,
  });

  factory InvoiceReceipt.fromJson(Map<String, dynamic> json) => InvoiceReceipt(
    id: json['id'] as String,
    branch: _branch(json['branch']),
    number: (json['number'] as num).toInt(),
    amountMinor: (json['amount_minor'] as num).toInt(),
    method: PaymentMethod.fromDb(json['method'] as String),
    receivedAt: _time(json['received_at']),
    recordedAt: _time(json['recorded_at']),
    recordedByName: json['recorded_by_name'] as String,
    replacesReceiptId: json['replaces_receipt_id'] as String?,
    voided: VoidStamp.fromJson(json),
  );

  final String id;

  /// Where the money changed hands; may differ from the invoice's branch.
  final ClinicLocation branch;
  final int number;
  final int amountMinor;
  final PaymentMethod method;

  /// When the money was taken. A corrected receipt keeps the original time.
  final DateTime receivedAt;
  final DateTime recordedAt;
  final String recordedByName;
  final String? replacesReceiptId;
  final VoidStamp? voided;

  bool get isVoided => voided != null;
  String get displayNumber => invoiceNumberLabel(branch, number);
}

/// Sessions and value taken off one invoice line by a refund.
class RefundLine {
  const RefundLine({required this.lineId, required this.sessionsCancelled, required this.valueMinor});

  factory RefundLine.fromJson(Map<String, dynamic> json) => RefundLine(
    lineId: json['line_id'] as String,
    sessionsCancelled: (json['sessions_cancelled'] as num).toInt(),
    valueMinor: (json['value_minor'] as num).toInt(),
  );

  final String lineId;
  final int sessionsCancelled;
  final int valueMinor;
}

/// Matches `invoice_refunds.kind`. Both lower the invoice value and may hand
/// money back; only a refund cancels sessions.
enum ReductionKind {
  /// Requested by the patient, usually when stopping treatment.
  refund,

  /// Given by the clinic after the invoice was issued.
  discount;

  static ReductionKind fromDb(Object? value) => value == 'discount' ? discount : refund;
}

/// A reduction of the invoice value after it was issued: a refund or a
/// discount. Each has its own number series.
class InvoiceRefund {
  const InvoiceRefund({
    required this.id,
    required this.branch,
    required this.number,
    required this.valueMinor,
    required this.paybackMinor,
    required this.reason,
    required this.recordedAt,
    required this.recordedByName,
    this.kind = ReductionKind.refund,
    this.paybackMethod,
    this.voided,
    this.lines = const [],
  });

  factory InvoiceRefund.fromJson(Map<String, dynamic> json) => InvoiceRefund(
    id: json['id'] as String,
    kind: ReductionKind.fromDb(json['kind']),
    branch: _branch(json['branch']),
    number: (json['number'] as num).toInt(),
    valueMinor: (json['value_minor'] as num).toInt(),
    paybackMinor: (json['payback_minor'] as num).toInt(),
    paybackMethod: json['payback_method'] == null
        ? null
        : PaymentMethod.fromDb(json['payback_method'] as String),
    reason: json['reason'] as String,
    recordedAt: _time(json['recorded_at']),
    recordedByName: json['recorded_by_name'] as String,
    voided: VoidStamp.fromJson(json),
    lines: [
      for (final Object? line in json['lines'] as List<Object?>? ?? const [])
        RefundLine.fromJson(line! as Map<String, dynamic>),
    ],
  );

  final String id;
  final ReductionKind kind;
  final ClinicLocation branch;
  final int number;

  /// How much the invoice value was reduced.
  final int valueMinor;

  /// Money actually handed back; zero when the refund only cancelled debt.
  final int paybackMinor;
  final PaymentMethod? paybackMethod;
  final String reason;
  final DateTime recordedAt;
  final String recordedByName;
  final VoidStamp? voided;
  final List<RefundLine> lines;

  bool get isVoided => voided != null;
  bool get isDiscount => kind == ReductionKind.discount;
  String get displayNumber => invoiceNumberLabel(branch, number);
  int get sessionsCancelled => lines.fold(0, (sum, line) => sum + line.sessionsCancelled);
}
