import 'billing_report_rows.dart';
import 'billing_report_summary_rows.dart';
import 'doctor_session_rows.dart';

export 'billing_report_rows.dart';
export 'billing_report_summary_rows.dart';
export 'doctor_session_rows.dart';

part 'billing_report_sessions.dart';

int _int(Object? value) => (value as num?)?.toInt() ?? 0;

List<T> _list<T>(Object? value, T Function(Map<String, dynamic> json) parse) => [
  for (final item in value as List? ?? const []) parse(item as Map<String, dynamic>),
];

/// One report as returned by `invoice_report` or `doctor_session_report`.
/// Totals always cover every row; [rows] may be capped, in which case [isTruncated] is true.
sealed class BillingReportData {
  const BillingReportData({required this.rowCount});

  /// Rows the totals were computed from.
  final int rowCount;
  int get shownCount;
  bool get isTruncated => rowCount > shownCount;
  bool get isEmpty => shownCount == 0;
}

/// Cash and Visa received and paid back.
class MoneyReport extends BillingReportData {
  const MoneyReport({
    required super.rowCount,
    required this.cashInMinor,
    required this.visaInMinor,
    required this.cashOutMinor,
    required this.visaOutMinor,
    required this.rows,
    required this.staff,
    required this.voids,
  });

  factory MoneyReport.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'] as Map<String, dynamic>;
    return MoneyReport(
      rowCount: _int(totals['row_count']),
      cashInMinor: _int(totals['cash_in_minor']),
      visaInMinor: _int(totals['visa_in_minor']),
      cashOutMinor: _int(totals['cash_out_minor']),
      visaOutMinor: _int(totals['visa_out_minor']),
      rows: _list(json['rows'], MoneyRow.fromJson),
      staff: _list(json['staff'], MoneyStaffRow.fromJson),
      voids: _list(json['voids'], VoidedRow.fromJson),
    );
  }

  final int cashInMinor;
  final int visaInMinor;
  final int cashOutMinor;
  final int visaOutMinor;
  final List<MoneyRow> rows;
  final List<MoneyStaffRow> staff;
  final List<VoidedRow> voids;

  int get netCashMinor => cashInMinor - cashOutMinor;
  int get netVisaMinor => visaInMinor - visaOutMinor;
  int get receivedMinor => cashInMinor + visaInMinor;
  int get paidBackMinor => cashOutMinor + visaOutMinor;

  @override
  int get shownCount => rows.length;

  @override
  bool get isEmpty => rows.isEmpty && voids.isEmpty;
}

/// Paid money per service line. For one doctor, [totalMinor], [cashMinor],
/// [visaMinor] and each row's share are that doctor's part; for all doctors,
/// [byDoctor] splits the same money between them.
class RevenueReport extends BillingReportData {
  const RevenueReport({
    required super.rowCount,
    required this.totalMinor,
    required this.cashMinor,
    required this.visaMinor,
    required this.movedMinor,
    required this.rows,
    this.byDoctor,
  });

  factory RevenueReport.fromJson(Map<String, dynamic> json, {DoctorTotals? byDoctor}) {
    final totals = json['totals'] as Map<String, dynamic>;
    return RevenueReport(
      rowCount: _int(totals['row_count']),
      totalMinor: _int(totals['collected_minor'] ?? totals['share_minor']),
      cashMinor: _int(totals['cash_minor']),
      visaMinor: _int(totals['visa_minor']),
      movedMinor: _int(totals['moved_minor']),
      rows: _list(json['rows'], RevenueRow.fromJson),
      byDoctor: byDoctor,
    );
  }

  final int totalMinor;
  final int cashMinor;
  final int visaMinor;

  /// Money a refund or discount moved between lines without paying anything back.
  final int movedMinor;
  final List<RevenueRow> rows;

  /// Null when the report is for one doctor.
  final DoctorTotals? byDoctor;
  bool get forDoctor => byDoctor == null;

  @override
  int get shownCount => rows.length;
}

/// Paid money credited to each doctor, from `invoice_report` kind
/// `doctors`. The row without a doctor holds money on lines with no
/// doctor, so the rows add up to everything paid.
class DoctorTotals {
  const DoctorTotals({
    required this.totalMinor,
    required this.cashMinor,
    required this.visaMinor,
    required this.movedMinor,
    required this.rows,
  });

  factory DoctorTotals.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'] as Map<String, dynamic>;
    return DoctorTotals(
      totalMinor: _int(totals['share_minor']),
      cashMinor: _int(totals['cash_minor']),
      visaMinor: _int(totals['visa_minor']),
      movedMinor: _int(totals['moved_minor']),
      rows: _list(json['rows'], DoctorSummaryRow.fromJson),
    );
  }

  final int totalMinor;
  final int cashMinor;
  final int visaMinor;
  final int movedMinor;
  final List<DoctorSummaryRow> rows;
}

/// Unpaid balances per patient.
class OutstandingReport extends BillingReportData {
  const OutstandingReport({
    required super.rowCount,
    required this.dueMinor,
    required this.openInvoices,
    required this.rows,
  });

  factory OutstandingReport.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'] as Map<String, dynamic>;
    return OutstandingReport(
      rowCount: _int(totals['row_count']),
      dueMinor: _int(totals['due_minor']),
      openInvoices: _int(totals['open_invoices']),
      rows: _list(json['rows'], OutstandingRow.fromJson),
    );
  }

  final int dueMinor;
  final int openInvoices;
  final List<OutstandingRow> rows;

  @override
  int get shownCount => rows.length;
}

/// Services sold, with the invoice lines behind each one.
class ServicesReport extends BillingReportData {
  const ServicesReport({
    required super.rowCount,
    required this.units,
    required this.billedMinor,
    required this.collectedMinor,
    required this.rows,
    required this.lines,
  });

  factory ServicesReport.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'] as Map<String, dynamic>;
    return ServicesReport(
      rowCount: _int(totals['row_count']),
      units: _int(totals['units']),
      billedMinor: _int(totals['billed_minor']),
      collectedMinor: _int(totals['collected_minor']),
      rows: _list(json['rows'], ServiceSummaryRow.fromJson),
      lines: _list(json['lines'], ServiceSaleRow.fromJson),
    );
  }

  final int units;
  final int billedMinor;
  final int collectedMinor;
  final List<ServiceSummaryRow> rows;
  final List<ServiceSaleRow> lines;

  List<ServiceSaleRow> linesOf(String serviceId) =>
      lines.where((line) => line.serviceId == serviceId).toList();

  @override
  int get shownCount => lines.length;
}
