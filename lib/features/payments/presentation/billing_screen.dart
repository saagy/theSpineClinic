import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/app_routes.dart';
import '../../../shared/widgets/refresh_on_return.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/invoice_access.dart';
import 'billing_report_providers.dart';
import 'widgets/invoice_access_gate.dart';
import 'widgets/report_actions.dart';
import 'widgets/report_body.dart';
import 'widgets/report_labels.dart';
import 'widgets/report_tabs.dart';
import 'widgets/report_toolbar.dart';

const _t = AppStrings.invoices;

/// The Billing tab for payment staff and super admins: five reports that
/// share a period, branch and doctor, with A4 printing. The service catalog
/// opens from the app bar.
class BillingScreen extends ConsumerWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => InvoiceManageGate(
    frame: (body) => _frame(context, body),
    loading: const SizedBox.shrink(),
    builder: (_) => _frame(context, _reports(context, ref), tabs: true),
  );

  Widget _frame(BuildContext context, Widget body, {bool tabs = false}) => Scaffold(
    appBar: AppBar(
      title: Text(_t.billing),
      actions: [
        if (tabs)
          TextButton.icon(
            onPressed: () => context.push(AppRoutes.serviceCatalog),
            icon: const Icon(Icons.medical_services_outlined, size: AppSizes.iconSmall),
            label: Text(_t.services, style: AppTextStyles.bodyMedium),
            style: TextButton.styleFrom(
              minimumSize: const Size(AppSizes.tappableMin, AppSizes.tappableMin),
            ),
          ),
        const SizedBox(width: AppSizes.p8),
      ],
    ),
    body: SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.reportContentMaxWidth),
          child: body,
        ),
      ),
    ),
  );

  Widget _reports(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(billingReportFilterControllerProvider);
    final DateTime now = DateTime.now();
    final query = filter.query(now);
    final view = ref.watch(billingReportViewProvider(query)).value;
    final bool hasRows =
        view != null && view.sections.any((section) => section.sheet.rows.isNotEmpty);
    Future<void> refresh() async {
      ref.invalidate(billingReportProvider(query));
      // The body shows a failed refresh; pull-to-refresh only needs to end.
      await ref.read(billingReportViewProvider(query).future).then((_) {}, onError: (_) {});
    }

    // Back from an invoice or patient, or into the app again: reload in
    // place, since payments, check-ins and other staff may have changed it.
    void refreshOnReturn() {
      if (!ref.read(billingReportProvider(query)).isLoading) {
        ref.invalidate(billingReportProvider(query));
      }
    }

    final colors = Theme.of(context).colorScheme;
    return RefreshOnReturn(
      notifyOnEntry: false,
      onReturn: refreshOnReturn,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ReportTabs(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: refresh,
              child: ListView(
                // Each report opens at its top.
                key: ValueKey(filter.kind),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.p16,
                  AppSizes.p16,
                  AppSizes.p16,
                  AppSizes.p32,
                ),
                children: [
                  ReportToolbar(
                    onRefresh: refresh,
                    onPrint: hasRows ? () => printReport(context, filter, view) : null,
                  ),
                  const SizedBox(height: AppSizes.p12),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: filter.periodLabel(now),
                          style: AppTextStyles.captionBold.copyWith(color: colors.onSurface),
                        ),
                        if (filter.branch case final branch?
                            when InvoiceAccess.fixedBranch(ref.watch(currentUserProvider).value) !=
                                null)
                          TextSpan(
                            text: '  ·  ${branch.displayLabel}',
                            style: AppTextStyles.captionBold.copyWith(color: colors.onSurface),
                          ),
                        TextSpan(text: '  ·  ${filter.help}'),
                      ],
                    ),
                    style: AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSizes.p16),
                  ReportBody(query: query),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
