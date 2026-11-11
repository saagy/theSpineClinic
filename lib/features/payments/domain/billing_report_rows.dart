import '../../patient/domain/clinic_location.dart';
import 'invoice_documents.dart';
import 'invoice_summary.dart';

int _int(Object? value) => (value as num?)?.toInt() ?? 0;
DateTime _time(Object? value) => DateTime.parse(value! as String);
ClinicLocation _branch(Object? value) =>
    ClinicLocation.values.firstWhere((branch) => branch.dbValue == value);
PaymentMethod? _method(Object? value) =>
    value == null ? null : PaymentMethod.fromDb(value as String);

/// Receipt, refund or invoice, as the reports name documents.
enum ReportDocumentKind {
  receipt,
  refund,
  invoice;

  static ReportDocumentKind fromDb(Object? value) =>
      values.firstWhere((kind) => kind.name == value, orElse: () => receipt);
}

/// The patient and invoice a report row belongs to.
class ReportParty {
  const ReportParty({
    required this.patientId,
    required this.patientName,
    required this.fileNumber,
    required this.invoiceId,
    required this.invoiceNumber,
  });

  factory ReportParty.fromJson(Map<String, dynamic> json) => ReportParty(
    patientId: json['patient_id'] as String,
    patientName: json['patient_name'] as String? ?? '',
    fileNumber: _int(json['file_number']),
    invoiceId: json['invoice_id'] as String,
    invoiceNumber: invoiceNumberLabel(_branch(json['invoice_branch']), _int(json['invoice_number'])),
  );

  final String patientId;
  final String patientName;
  final int fileNumber;
  final String invoiceId;
  final String invoiceNumber;
}

/// One receipt, or one refund that paid money back.
class MoneyRow {
  const MoneyRow({
    required this.kind,
    required this.number,
    required this.branch,
    required this.at,
    required this.method,
    required this.amountMinor,
    required this.recordedBy,
    required this.party,
  });

  factory MoneyRow.fromJson(Map<String, dynamic> json) => MoneyRow(
    kind: ReportDocumentKind.fromDb(json['kind']),
    number: invoiceNumberLabel(_branch(json['branch']), _int(json['number'])),
    branch: _branch(json['branch']),
    at: _time(json['moved_at']),
    method: _method(json['method']) ?? PaymentMethod.cash,
    amountMinor: _int(json['amount_minor']),
    recordedBy: json['recorded_by_name'] as String? ?? '',
    party: ReportParty.fromJson(json),
  );

  final ReportDocumentKind kind;
  final String number;
  final ClinicLocation branch;
  final DateTime at;
  final PaymentMethod method;

  /// Always positive; refunds are money out.
  final int amountMinor;
  final String recordedBy;
  final ReportParty party;

  int get signedMinor => kind == ReportDocumentKind.refund ? -amountMinor : amountMinor;
}

class MoneyStaffRow {
  const MoneyStaffRow({
    required this.name,
    required this.cashInMinor,
    required this.visaInMinor,
    required this.cashOutMinor,
    required this.visaOutMinor,
  });

  factory MoneyStaffRow.fromJson(Map<String, dynamic> json) => MoneyStaffRow(
    name: json['name'] as String? ?? '',
    cashInMinor: _int(json['cash_in_minor']),
    visaInMinor: _int(json['visa_in_minor']),
    cashOutMinor: _int(json['cash_out_minor']),
    visaOutMinor: _int(json['visa_out_minor']),
  );

  final String name;
  final int cashInMinor;
  final int visaInMinor;
  final int cashOutMinor;
  final int visaOutMinor;

  int get netMinor => cashInMinor + visaInMinor - cashOutMinor - visaOutMinor;
}

/// A document voided in the period.
class VoidedRow {
  const VoidedRow({
    required this.kind,
    required this.number,
    required this.amountMinor,
    required this.voidedAt,
    required this.voidedBy,
    required this.reason,
    required this.party,
  });

  factory VoidedRow.fromJson(Map<String, dynamic> json) => VoidedRow(
    kind: ReportDocumentKind.fromDb(json['kind']),
    number: invoiceNumberLabel(_branch(json['branch']), _int(json['number'])),
    amountMinor: _int(json['amount_minor']),
    voidedAt: _time(json['voided_at']),
    voidedBy: json['voided_by_name'] as String? ?? '',
    reason: json['void_reason'] as String? ?? '',
    party: ReportParty.fromJson(json),
  );

  final ReportDocumentKind kind;
  final String number;
  final int amountMinor;
  final DateTime voidedAt;
  final String voidedBy;
  final String reason;
  final ReportParty party;
}
