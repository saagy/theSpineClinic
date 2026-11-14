import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../domain/billing_report.dart';
import '../../domain/billing_report_data.dart';
import '../../domain/invoice_access.dart';
import '../billing_report_providers.dart';
import '../billing_report_view.dart';
import 'report_figures.dart';
import 'report_table.dart';

const _t = AppStrings.billingReports;

/// The selected report: totals, then its tables. Handles loading, failure,
/// an empty period and capped rows. Doctor rows narrow the report to them.
class ReportBody extends ConsumerWidget {
  const ReportBody({super.key, required this.query});
  final BillingReportQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BillingReportKind kind = query.kind;
    void showDoctor(String id, String name) =>
        ref.read(billingReportFilterControllerProvider.notifier).setDoctor(id, name);
    final report = ref.watch(billingReportProvider(query)).value;
    return ref
        .watch(billingReportViewProvider(query))
        .when(
          skipLoadingOnRefresh: true,
          loading: () => const _ReportSkeleton(),
          error: (error, _) => _centered(
            ErrorView(
              exception: AppException.fromSupabaseException(error),
              onRetry: () => ref.invalidate(billingReportProvider(query)),
            ),
          ),
          data: (view) => report == null || report.isEmpty
              ? _centered(
                  EmptyState(
                    icon: kind.usesDates ? Icons.event_busy_outlined : Icons.check_circle_outline,
                    message: kind.usesDates ? _t.empty : _t.emptyOutstanding,
                    secondaryMessage: !kind.usesDates
                        ? _t.emptyOutstandingHelp
                        // Receptionists with a branch have no branch to change.
                        : InvoiceAccess.fixedBranch(ref.watch(currentUserProvider).value) == null
                        ? _t.emptyHelp
                        : _t.emptyHelpPeriod,
                  ),
                )
              : _loaded(view, report, showDoctor),
        );
  }

  Widget _loaded(
    ReportView view,
    BillingReportData report,
    void Function(String id, String name) showDoctor,
  ) {
    final shown = [
      for (final section in view.sections)
        if (!section.printOnly && (section.sheet.rows.isNotEmpty || section.emptyMessage != null))
          section,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReportFigures(figures: view.figures),
        if (report.isTruncated) ...[
          const SizedBox(height: AppSizes.p12),
          _Notice(_t.truncated(report.shownCount, report.rowCount)),
        ],
        for (final (index, section) in shown.indexed)
          _Section(
            // A different report starts its tables on their first page.
            key: ValueKey((query, index)),
            section: section,
            showTitle: shown.length > 1,
            onDoctor: showDoctor,
          ),
      ],
    );
  }

  Widget _centered(Widget child) => Padding(
    padding: const EdgeInsets.only(top: AppSizes.p48),
    child: child,
  );
}

class _Section extends StatelessWidget {
  const _Section({
    super.key,
    required this.section,
    required this.showTitle,
    required this.onDoctor,
  });
  final ReportSection section;
  final bool showTitle;
  final void Function(String id, String name) onDoctor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final muted = AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: showTitle ? AppSizes.p24 : AppSizes.p12),
        if (showTitle && section.title != null)
          Semantics(header: true, child: Text(section.title!, style: AppTextStyles.headingSmall)),
        if (showTitle && section.note != null) Text(section.note!, style: muted),
        if (showTitle) const SizedBox(height: AppSizes.p4),
        if (section.sheet.rows.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSizes.p4),
            child: Text(
              section.emptyMessage!,
              style: AppTextStyles.body.copyWith(color: colors.onSurfaceVariant),
            ),
          )
        else
          ReportTable(sheet: section.sheet, onDoctor: onDoctor),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: AppSizes.iconSmall, color: colors.onSurfaceVariant),
        const SizedBox(width: AppSizes.p8),
        Expanded(
          child: Text(
            message,
            style: AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

/// Totals strip and table rows while a report loads.
class _ReportSkeleton extends StatelessWidget {
  const _ReportSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget surface(Widget child) => Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(AppSizes.r12),
      ),
      child: Padding(padding: const EdgeInsets.all(AppSizes.p16), child: child),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        surface(
          const Row(
            children: [
              Expanded(child: _SkeletonFigure()),
              Expanded(child: _SkeletonFigure()),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.p24),
        surface(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int row = 0; row < 6; row++) ...[
                if (row > 0) const SizedBox(height: AppSizes.p20),
                const SkeletonBox(width: 220, height: AppSizes.p14),
                const SizedBox(height: AppSizes.p8),
                const SkeletonBox(width: 140, height: AppSizes.p12),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SkeletonFigure extends StatelessWidget {
  const _SkeletonFigure();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SkeletonBox(width: 72, height: AppSizes.p12),
      SizedBox(height: AppSizes.p8),
      SkeletonBox(width: 112, height: AppSizes.p20),
    ],
  );
}
