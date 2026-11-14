import '../../../../shared/widgets/app_date_range_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/doctor_picker_sheet.dart';
import '../../domain/billing_report.dart';
import '../billing_report_pdf.dart';
import '../billing_report_providers.dart';
import '../billing_report_view.dart';
import 'report_labels.dart';

const _t = AppStrings.billingReports;

Future<void> printReport(BuildContext context, BillingReportFilter filter, ReportView view) async {
  final DateTime now = DateTime.now();
  final bool printed = await BillingReportPdf.print(
    title: filter.kind.label,
    period: filter.periodLabel(now),
    scope: filter.scopeLabel(),
    view: view,
    fileName: filter.fileName(now),
  );
  if (!printed && context.mounted) {
    AppSnackbar.show(context, message: _t.printFailed, variant: AppSnackbarVariant.error);
  }
}

/// Opens the shared doctor picker and applies the choice to the reports.
Future<void> pickReportDoctor(BuildContext context, WidgetRef ref) async {
  final filter = ref.read(billingReportFilterControllerProvider);
  final doctor = await DoctorPickerSheet.showSingle(
    context: context,
    selectedDoctorId: filter.doctorId,
    title: _t.chooseDoctor,
  );
  if (doctor == null) return;
  ref.read(billingReportFilterControllerProvider.notifier).setDoctor(doctor.id, doctor.fullName);
}

/// Asks for a custom period of up to one year, ending today at the latest.
Future<void> pickReportRange(BuildContext context, WidgetRef ref) async {
  final DateTime now = DateTime.now();
  final current = ref.read(billingReportFilterControllerProvider).range(now);
  final DateTimeRange? picked = await showAppDateRangePicker(
    context: context,
    firstDate: DateTime(2020),
    lastDate: DateTime(now.year, now.month, now.day),
    initialDateRange: DateTimeRange(start: current.from, end: current.to),
    helpText: _t.customRangeHelp,
  );
  if (picked == null || !context.mounted) return;
  final range = ReportRange(picked.start, picked.end);
  if (!range.isValid) {
    AppSnackbar.show(context, message: _t.rangeTooLong, variant: AppSnackbarVariant.error);
    return;
  }
  ref.read(billingReportFilterControllerProvider.notifier).setCustomRange(range);
}
