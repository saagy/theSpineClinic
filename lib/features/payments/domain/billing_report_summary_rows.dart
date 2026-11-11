import 'billing_report_rows.dart';
import 'invoice_documents.dart';

int _int(Object? value) => (value as num?)?.toInt() ?? 0;
DateTime _time(Object? value) => DateTime.parse(value! as String);
PaymentMethod? _method(Object? value) =>
    value == null ? null : PaymentMethod.fromDb(value as String);

/// Money collected for (or taken back from) one invoice line.
class RevenueRow {
  const RevenueRow({
    required this.at,
    required this.kind,
    required this.method,
    required this.amountMinor,
    required this.shareMinor,
    required this.serviceName,
    required this.priceMinor,
    required this.doctors,
    required this.party,
  });

  factory RevenueRow.fromJson(Map<String, dynamic> json) => RevenueRow(
    at: _time(json['moved_at']),
    kind: ReportDocumentKind.fromDb(json['kind']),
    method: _method(json['method']),
    amountMinor: _int(json['amount_minor']),
    shareMinor: json['share_minor'] == null ? null : _int(json['share_minor']),
    serviceName: json['service_name'] as String? ?? '',
    priceMinor: _int(json['price_minor']),
    doctors: (json['doctors'] as List? ?? const []).whereType<String>().toList(),
    party: ReportParty.fromJson(json),
  );

  final DateTime at;
  final ReportDocumentKind kind;

  /// Null when a refund only moved money between lines.
  final PaymentMethod? method;
  final int amountMinor;

  /// The selected doctor's part, on the doctor revenue report only.
  final int? shareMinor;
  final String serviceName;
  final int priceMinor;
  final List<String> doctors;
  final ReportParty party;
}

class DoctorSummaryRow {
  const DoctorSummaryRow({
    required this.doctorId,
    required this.name,
    required this.shareMinor,
    required this.cashMinor,
    required this.visaMinor,
    required this.movedMinor,
  });

  factory DoctorSummaryRow.fromJson(Map<String, dynamic> json) => DoctorSummaryRow(
    doctorId: json['doctor_id'] as String?,
    name: json['doctor_name'] as String?,
    shareMinor: _int(json['share_minor']),
    cashMinor: _int(json['cash_minor']),
    visaMinor: _int(json['visa_minor']),
    movedMinor: _int(json['moved_minor']),
  );

  /// Null for money on lines without doctor credit.
  final String? doctorId;
  final String? name;
  final int shareMinor;
  final int cashMinor;
  final int visaMinor;
  final int movedMinor;
}

class OutstandingRow {
  const OutstandingRow({
    required this.patientId,
    required this.patientName,
    required this.fileNumber,
    required this.openInvoices,
    required this.dueMinor,
    required this.oldestDate,
  });

  factory OutstandingRow.fromJson(Map<String, dynamic> json) => OutstandingRow(
    patientId: json['patient_id'] as String,
    patientName: json['patient_name'] as String? ?? '',
    fileNumber: _int(json['file_number']),
    openInvoices: _int(json['open_invoices']),
    dueMinor: _int(json['due_minor']),
    oldestDate: _time(json['oldest_date']),
  );

  final String patientId;
  final String patientName;
  final int fileNumber;
  final int openInvoices;
  final int dueMinor;
  final DateTime oldestDate;
}

class ServiceSummaryRow {
  const ServiceSummaryRow({
    required this.serviceId,
    required this.name,
    required this.serviceType,
    required this.units,
    required this.invoiceCount,
    required this.billedMinor,
    required this.collectedMinor,
  });

  factory ServiceSummaryRow.fromJson(Map<String, dynamic> json) => ServiceSummaryRow(
    serviceId: json['service_id'] as String,
    name: json['service_name'] as String? ?? '',
    serviceType: json['service_type'] as String? ?? '',
    units: _int(json['units']),
    invoiceCount: _int(json['invoice_count']),
    billedMinor: _int(json['billed_minor']),
    collectedMinor: _int(json['collected_minor']),
  );

  final String serviceId;
  final String name;
  final String serviceType;
  final int units;
  final int invoiceCount;
  final int billedMinor;
  final int collectedMinor;
}

/// One invoice line behind a service's totals.
class ServiceSaleRow {
  const ServiceSaleRow({
    required this.serviceId,
    required this.invoiceDate,
    required this.quantity,
    required this.billedMinor,
    required this.collectedMinor,
    required this.party,
  });

  factory ServiceSaleRow.fromJson(Map<String, dynamic> json) => ServiceSaleRow(
    serviceId: json['service_id'] as String,
    invoiceDate: _time(json['invoice_date']),
    quantity: _int(json['quantity']),
    billedMinor: _int(json['billed_minor']),
    collectedMinor: _int(json['collected_minor']),
    party: ReportParty.fromJson(json),
  );

  final String serviceId;
  final DateTime invoiceDate;
  final int quantity;
  final int billedMinor;
  final int collectedMinor;
  final ReportParty party;
}
