import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/billing_report.dart';
import '../billing_report_providers.dart';

const _t = AppStrings.billingReports;

extension BillingReportKindLabels on BillingReportKind {
  String get label => switch (this) {
    BillingReportKind.money => _t.money,
    BillingReportKind.revenue => _t.revenue,
    BillingReportKind.doctor => _t.doctor,
    BillingReportKind.doctors => _t.doctors,
    BillingReportKind.outstanding => _t.outstanding,
    BillingReportKind.services => _t.services,
  };

  String get help => switch (this) {
    BillingReportKind.money => _t.moneyHelp,
    BillingReportKind.revenue => _t.revenueHelp,
    BillingReportKind.doctor => _t.doctorHelp,
    BillingReportKind.doctors => _t.doctorsHelp,
    BillingReportKind.outstanding => _t.outstandingHelp,
    BillingReportKind.services => _t.servicesHelp,
  };

  /// Lowercase name used in exported file names.
  String get fileStem => switch (this) {
    BillingReportKind.money => 'daily-money',
    BillingReportKind.revenue => 'revenue',
    BillingReportKind.doctor => 'doctor-revenue',
    BillingReportKind.doctors => 'doctors-summary',
    BillingReportKind.outstanding => 'outstanding',
    BillingReportKind.services => 'services',
  };
}

extension ReportPeriodLabels on ReportPeriod {
  String get label => switch (this) {
    ReportPeriod.today => _t.today,
    ReportPeriod.yesterday => _t.yesterday,
    ReportPeriod.last7Days => _t.last7Days,
    ReportPeriod.thisMonth => _t.thisMonth,
    ReportPeriod.lastMonth => _t.lastMonth,
    ReportPeriod.custom => _t.customRange,
  };

  IconData get icon => switch (this) {
    ReportPeriod.custom => Icons.date_range_outlined,
    ReportPeriod.today || ReportPeriod.yesterday => Icons.today_outlined,
    _ => Icons.calendar_month_outlined,
  };
}

extension BillingReportFilterLabels on BillingReportFilter {
  /// The days covered, such as `Nov 1, 2026 – Nov 11, 2026`.
  String periodLabel(DateTime now) {
    if (!kind.usesDates) return _t.asOfNow;
    final range = this.range(now);
    return _t.rangeLabel(
      Formatters.formatDateMedium(range.from),
      Formatters.formatDateMedium(range.to),
    );
  }

  /// Branch and doctor, for the printed header.
  String scopeLabel() => [
    branch?.displayLabel ?? _t.allBranches,
    if (kind.usesDoctor && doctorName != null) doctorName!,
  ].join(' · ');

  String fileName(DateTime now) {
    final range = this.range(now);
    return kind.usesDates
        ? _t.fileName(kind.fileStem, ReportRange.isoDay(range.from), ReportRange.isoDay(range.to))
        : '${kind.fileStem}-${ReportRange.isoDay(now)}';
  }
}
