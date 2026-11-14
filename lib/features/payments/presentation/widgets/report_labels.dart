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
    BillingReportKind.sessions => _t.sessions,
    BillingReportKind.services => _t.services,
    BillingReportKind.outstanding => _t.outstanding,
  };

  IconData get icon => switch (this) {
    BillingReportKind.money => Icons.payments_outlined,
    BillingReportKind.revenue => Icons.insights_outlined,
    BillingReportKind.sessions => Icons.event_available_outlined,
    BillingReportKind.services => Icons.medical_services_outlined,
    BillingReportKind.outstanding => Icons.pending_actions_outlined,
  };

  /// One short sentence on what the report shows.
  String help({String? doctorName}) => switch (this) {
    BillingReportKind.money => _t.moneyHelp,
    BillingReportKind.revenue when doctorName != null => _t.doctorHelp(doctorName),
    BillingReportKind.revenue => _t.revenueHelp,
    BillingReportKind.sessions => _t.sessionsHelp,
    BillingReportKind.services => _t.servicesHelp,
    BillingReportKind.outstanding => _t.outstandingHelp,
  };

  /// Lowercase name used in printed file names.
  String get fileStem => switch (this) {
    BillingReportKind.money => 'payments-and-refunds',
    BillingReportKind.revenue => 'revenue',
    BillingReportKind.sessions => 'doctor-sessions',
    BillingReportKind.services => 'services',
    BillingReportKind.outstanding => 'balances-due',
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
    final String stem = kind.usesDoctor && doctorName != null
        ? '${kind.fileStem}-${doctorName!.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}'
        : kind.fileStem;
    return kind.usesDates
        ? _t.fileName(stem, ReportRange.isoDay(range.from), ReportRange.isoDay(range.to))
        : '$stem-${ReportRange.isoDay(now)}';
  }

  /// What the selected report shows, naming the doctor where one is chosen.
  String get help => kind.help(doctorName: kind.usesDoctor && doctorId != null ? doctorName : null);
}
