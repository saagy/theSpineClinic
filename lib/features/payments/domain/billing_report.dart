import '../../patient/domain/clinic_location.dart';
import 'billing_report_data.dart';
import '../../../core/errors/result.dart';

/// The Billing tab reports. Values match the `invoice_report` kinds.
enum BillingReportKind {
  money,
  revenue,
  doctor,
  doctors,
  outstanding,
  services;

  /// Outstanding balances are always as of now.
  bool get usesDates => this != outstanding;
  bool get usesDoctor => this == revenue || this == doctor;
  bool get requiresDoctor => this == doctor;
}

enum ReportPeriod { today, yesterday, last7Days, thisMonth, lastMonth, custom }

/// Inclusive clinic days.
class ReportRange {
  ReportRange(DateTime from, DateTime to)
    : from = DateTime(from.year, from.month, from.day),
      to = DateTime(to.year, to.month, to.day);

  /// The database rejects longer periods.
  static const int maxDays = 366;

  factory ReportRange.of(ReportPeriod period, DateTime now, {ReportRange? custom}) {
    final DateTime day = DateTime(now.year, now.month, now.day);
    return switch (period) {
      ReportPeriod.today => ReportRange(day, day),
      ReportPeriod.yesterday => ReportRange(
        DateTime(day.year, day.month, day.day - 1),
        DateTime(day.year, day.month, day.day - 1),
      ),
      ReportPeriod.last7Days => ReportRange(DateTime(day.year, day.month, day.day - 6), day),
      ReportPeriod.thisMonth => ReportRange(DateTime(day.year, day.month), day),
      ReportPeriod.lastMonth => ReportRange(
        DateTime(day.year, day.month - 1),
        DateTime(day.year, day.month, 0),
      ),
      ReportPeriod.custom => custom ?? ReportRange(day, day),
    };
  }

  final DateTime from;
  final DateTime to;

  bool get isValid => !to.isBefore(from) && to.difference(from).inDays <= maxDays;

  static String isoDay(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) => other is ReportRange && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

/// Everything that identifies one report request.
class BillingReportQuery {
  const BillingReportQuery({required this.kind, required this.range, this.branch, this.doctorId});
  final BillingReportKind kind;
  final ReportRange range;
  final ClinicLocation? branch;
  final String? doctorId;

  Map<String, Object?> toParams() => {
    'p_kind': kind.name,
    'p_from': ReportRange.isoDay(range.from),
    'p_to': ReportRange.isoDay(range.to),
    'p_branch': branch?.dbValue,
    'p_doctor': kind.usesDoctor ? doctorId : null,
  };

  @override
  bool operator ==(Object other) =>
      other is BillingReportQuery &&
      other.kind == kind &&
      other.range == range &&
      other.branch == branch &&
      other.doctorId == doctorId;

  @override
  int get hashCode => Object.hash(kind, range, branch, doctorId);
}

/// Read-only billing reports for payment receptionists and super admins.
abstract interface class BillingReportRepository {
  Future<Result<BillingReportData>> report(BillingReportQuery query);
}
