import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/record_action_menu.dart';
import '../../../../shared/widgets/record_menu_select.dart';
import '../../../patient/domain/clinic_location.dart';
import '../../domain/billing_report.dart';
import '../billing_report_providers.dart';
import 'report_actions.dart';
import 'report_labels.dart';

const _t = AppStrings.billingReports;

enum _ReportAction { refresh, export, print }

/// Period, branch and doctor for the selected report, with refresh, CSV
/// export and print. The actions collapse into one menu on narrow windows.
class ReportToolbar extends ConsumerWidget {
  const ReportToolbar({super.key, this.onRefresh, this.onExport, this.onPrint});

  /// Null while there is nothing to act on.
  final VoidCallback? onRefresh;
  final VoidCallback? onExport;
  final VoidCallback? onPrint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(billingReportFilterControllerProvider);
    final controller = ref.read(billingReportFilterControllerProvider.notifier);
    final filters = Wrap(
      spacing: AppSizes.p8,
      runSpacing: AppSizes.p8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (filter.kind.usesDates)
          RecordMenuSelect<ReportPeriod>(
            label: _t.period,
            value: filter.period,
            options: [
              for (final period in ReportPeriod.values)
                RecordMenuAction(
                  period,
                  period == ReportPeriod.custom && filter.period == ReportPeriod.custom
                      ? filter.periodLabel(DateTime.now())
                      : period.label,
                  period.icon,
                  dividerBefore: period == ReportPeriod.custom,
                ),
            ],
            onChanged: (period) => period == ReportPeriod.custom
                ? pickReportRange(context, ref)
                : controller.setPeriod(period),
          ),
        RecordMenuSelect<ClinicLocation?>(
          label: _t.branch,
          value: filter.branch,
          options: [
            RecordMenuAction(null, _t.allBranches, Icons.apartment_outlined),
            for (final branch in ClinicLocation.values)
              RecordMenuAction(branch, branch.displayLabel, Icons.location_on_outlined),
          ],
          onChanged: controller.setBranch,
        ),
        if (filter.kind.usesDoctor) _DoctorSelect(filter: filter),
      ],
    );
    return LayoutBuilder(
      builder: (context, box) {
        final bool roomy = box.maxWidth >= AppSizes.desktopBreakpoint &&
            MediaQuery.textScalerOf(context).scale(1) <= 1.3;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: filters),
            const SizedBox(width: AppSizes.p8),
            if (roomy) ...[
              IconButton(
                tooltip: _t.refresh,
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh, size: AppSizes.iconDefault),
              ),
              const SizedBox(width: AppSizes.p4),
              _button(_t.export, Icons.file_download_outlined, onExport),
              const SizedBox(width: AppSizes.p8),
              _button(_t.print, Icons.print_outlined, onPrint),
            ] else
              RecordActionMenu<_ReportAction>(
                tooltip: _t.more,
                onSelected: (action) => switch (action) {
                  _ReportAction.refresh => onRefresh?.call(),
                  _ReportAction.export => onExport?.call(),
                  _ReportAction.print => onPrint?.call(),
                },
                actions: [
                  RecordMenuAction(_ReportAction.refresh, _t.refresh, Icons.refresh,
                      enabled: onRefresh != null),
                  RecordMenuAction(_ReportAction.export, _t.export, Icons.file_download_outlined,
                      enabled: onExport != null),
                  RecordMenuAction(_ReportAction.print, _t.print, Icons.print_outlined,
                      enabled: onPrint != null),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _button(String label, IconData icon, VoidCallback? onPressed) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: AppSizes.iconSmall),
    label: Text(label, style: AppTextStyles.bodyMedium),
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(AppSizes.tappableMin, AppSizes.tappableMin),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r8)),
    ),
  );
}

/// Opens the shared doctor picker; a chosen doctor can be cleared where the
/// report also works for all doctors.
class _DoctorSelect extends ConsumerWidget {
  const _DoctorSelect({required this.filter});
  final BillingReportFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final bool chosen = filter.doctorId != null;
    final String label = filter.doctorName ??
        (filter.kind.requiresDoctor ? _t.chooseDoctor : _t.allDoctors);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Semantics(
            button: true,
            label: _t.doctorFilter,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSizes.r12),
              onTap: () => pickReportDoctor(context, ref),
              child: Container(
                constraints: const BoxConstraints(minHeight: AppSizes.tappableMin),
                padding: const EdgeInsets.all(AppSizes.p12),
                decoration: BoxDecoration(
                  border: Border.all(color: colors.outlineVariant),
                  borderRadius: BorderRadius.circular(AppSizes.r12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        style: AppTextStyles.bodyMedium.copyWith(color: colors.onSurface),
                      ),
                    ),
                    const SizedBox(width: AppSizes.p8),
                    Icon(Icons.expand_more, color: colors.onSurfaceVariant, size: AppSizes.iconSmall),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (chosen && !filter.kind.requiresDoctor)
          IconButton(
            tooltip: _t.clearDoctor,
            onPressed: () => ref
                .read(billingReportFilterControllerProvider.notifier)
                .setDoctor(null, null),
            icon: const Icon(Icons.close, size: AppSizes.iconSmall),
          ),
      ],
    );
  }
}
