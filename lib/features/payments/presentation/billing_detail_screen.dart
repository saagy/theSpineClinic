import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/patient_id_label.dart';
import '../../../shared/widgets/record_action_menu.dart';
import '../domain/billing_invoice.dart';
import '../domain/billing_money.dart';
import '../domain/billing_repository.dart';
import 'billing_document_output.dart';
import 'billing_editor_fields.dart';
import 'billing_editor_screen.dart';
import 'billing_movement_dialog.dart';
import 'billing_providers.dart';
import 'billing_ui.dart';

part 'billing_detail_body.dart';

class BillingDetailScreen extends ConsumerWidget {
  const BillingDetailScreen({super.key, required this.invoiceId});
  final String invoiceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => BillingGate(
    child: Builder(
      builder: (context) {
        final provider = billingInvoiceProvider(invoiceId);
        final state = ref.watch(provider);
        final busy = ref.watch(billingWriterProvider).busy || state.isLoading;
        final invoice = state.value;
        return PopScope(
          canPop: !busy,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                invoice?.number == null
                    ? billingText.invoice
                    : '${billingText.invoice} #${invoice!.number}',
                style: AppTextStyles.headingSmall,
              ),
              actions: [
                IconButton(
                  tooltip: AppStrings.retrySave,
                  icon: const Icon(Icons.refresh),
                  onPressed: busy ? null : () => ref.invalidate(provider),
                ),
                RecordActionMenu<BillingAction>(
                  enabled: !busy,
                  tooltip: billingText.checkSave,
                  icon: Icons.history,
                  onSelected: (action) =>
                      recoverBilling(context, ref, action, invoiceId),
                  actions: [
                    for (final (action, icon) in const [
                      (BillingAction.issue, Icons.receipt_long_outlined),
                      (BillingAction.receipt, Icons.payments_outlined),
                      (BillingAction.credit, Icons.assignment_return_outlined),
                      (BillingAction.refund, Icons.undo),
                    ])
                      RecordMenuAction(action, _actionLabel(action), icon),
                  ],
                ),
              ],
            ),
            body: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  billingError(error, () => ref.invalidate(provider)),
              data: (value) => _body(context, ref, value, busy),
            ),
          ),
        );
      },
    ),
  );

  Widget _actions(
    BuildContext context,
    WidgetRef ref,
    BillingInvoice invoice,
    bool busy,
  ) => Wrap(
    spacing: AppSizes.p8,
    runSpacing: AppSizes.p8,
    children: invoice.isDraft
        ? [
            FilledButton(
              onPressed: busy ? null : () => _issue(context, ref, invoice),
              child: Text(billingText.review),
            ),
            OutlinedButton(
              onPressed: busy
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute<String>(
                        builder: (_) => BillingEditorScreen(invoice: invoice),
                      ),
                    ),
              child: Text(billingText.editDraft),
            ),
          ]
        : [
            if (invoice.outstanding > 0)
              FilledButton(
                onPressed: busy
                    ? null
                    : () => _movement(
                        context,
                        ref,
                        invoice,
                        BillingAction.receipt,
                      ),
                child: Text(billingText.collect),
              ),
            if (invoice.refundable > 0)
              FilledButton(
                onPressed: busy
                    ? null
                    : () => _movement(
                        context,
                        ref,
                        invoice,
                        BillingAction.refund,
                      ),
                child: Text(billingText.refund),
              ),
            if (invoice.lines.any(
              (line) => invoice.remainingQuantity(line) > 0,
            ))
              OutlinedButton(
                onPressed: busy
                    ? null
                    : () => _movement(
                        context,
                        ref,
                        invoice,
                        BillingAction.credit,
                      ),
                child: Text(billingText.credit),
              ),
            OutlinedButton.icon(
              onPressed: () => printBillingDocument(context, invoice),
              icon: const Icon(Icons.print_outlined),
              label: Text(billingText.print),
            ),
          ],
  );

  Future<void> _issue(
    BuildContext context,
    WidgetRef ref,
    BillingInvoice invoice,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(billingText.issue, style: AppTextStyles.headingSmall),
        content: Text(
          '${billingText.issueHelp}\n\n${billingPartyLabel(invoice.patient)}\n${billingAmount(invoice.total)}',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(billingText.issue),
          ),
        ],
      ),
    );
    if (context.mounted && confirmed == true) {
      await submitBilling(context, ref, BillingCommand.issue(invoice));
    }
  }

  Future<void> _movement(
    BuildContext context,
    WidgetRef ref,
    BillingInvoice invoice,
    BillingAction action,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BillingMovementDialog(invoice: invoice, action: action),
    );
  }

  String _actionLabel(BillingAction action) => switch (action) {
    BillingAction.issue => billingText.issue,
    BillingAction.receipt => billingText.collect,
    BillingAction.credit => billingText.credit,
    BillingAction.refund => billingText.refund,
    _ => billingText.saveDraft,
  };
}
