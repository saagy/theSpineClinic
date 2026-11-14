import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/app_routes.dart';
import '../../../../shared/widgets/record_section.dart';
import '../../../../shared/widgets/refresh_on_return.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../patient/domain/patient.dart';
import '../../../patient/presentation/patient_providers.dart';
import '../../../patient/presentation/widgets/workspace_tab_header.dart';
import '../../domain/invoice_access.dart';
import '../../domain/invoice_summary.dart';
import '../invoice_providers.dart';
import 'invoice_list_row.dart';
import 'invoice_totals_strip.dart';

const _t = AppStrings.invoices;

/// The patient workspace's Payments tab: money summary, then invoices
/// newest first. The workspace supplies scrolling and pull-to-refresh.
class PatientInvoicesTab extends ConsumerWidget {
  const PatientInvoicesTab({super.key, required this.patient});
  final Patient patient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = patientInvoicesProvider(patient.id);
    final bool canIssue = InvoiceAccess.canIssue(ref.watch(currentUserProvider).value);
    // Back on this tab or into the app again: other staff may have billed
    // the patient, which also moves their session balances.
    void refreshOnReturn() {
      if (ref.read(request).isLoading) return;
      ref.invalidate(request);
      ref.invalidate(patientDetailProvider(patient.id));
    }

    return RefreshOnReturn(
      notifyOnEntry: false,
      onReturn: refreshOnReturn,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WorkspaceTabHeader(
            title: AppStrings.payments,
            actionLabel: canIssue ? _t.newInvoice : null,
            onAction: canIssue
                ? () => context.push(AppRoutes.newInvoiceLocation(patient.id))
                : null,
          ),
          const SizedBox(height: AppSizes.p14),
          RecordAsync<List<InvoiceSummary>>(
            value: ref.watch(request),
            onRetry: () => ref.invalidate(request),
            data: (invoices) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InvoiceTotalsStrip(
                  totals: PatientInvoiceTotals.of(invoices),
                  ptSessions: patient.sessionBalance,
                  tractionSessions: patient.tractionBalance,
                ),
                const SizedBox(height: AppSizes.p20),
                if (invoices.isEmpty)
                  _surface(
                    context,
                    Padding(
                      padding: const EdgeInsets.all(AppSizes.p16),
                      child: RecordMessage(message: '${_t.noInvoices}. ${_t.noInvoicesHelp}'),
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, box) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (invoiceListIsWide(context, box.maxWidth)) const InvoiceListHeader(),
                        _surface(
                          context,
                          Column(
                            children: [
                              for (final (index, invoice) in invoices.indexed) ...[
                                if (index > 0)
                                  Divider(
                                    height: AppSizes.borderWidth,
                                    thickness: AppSizes.borderWidth,
                                    color: Theme.of(context).colorScheme.outlineVariant,
                                  ),
                                InkWell(
                                  onTap: () => context.push(
                                    AppRoutes.invoiceDetailLocation(patient.id, invoice.id),
                                  ),
                                  child: Semantics(
                                    button: true,
                                    hint: AppStrings.invoiceDetail.openInvoice,
                                    child: InvoiceListRow(invoice: invoice),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _surface(BuildContext context, Widget child) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(AppSizes.r12),
      ),
      child: child,
    );
  }
}
