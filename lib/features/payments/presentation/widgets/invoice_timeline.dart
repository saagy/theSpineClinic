import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/record_action_menu.dart';
import '../../domain/invoice_detail.dart';
import 'invoice_detail_actions.dart';
import 'invoice_timeline_row.dart';

const _t = AppStrings.invoiceDetail;

String paymentMethodLabel(PaymentMethod method) =>
    method == PaymentMethod.cash ? _t.cash : _t.visa;

enum _DocAction { print, correct, voidIt }

/// Everything that happened to the invoice, oldest first: its creation, each
/// receipt and refund (voided ones stay visible), and the invoice's own void.
class InvoiceTimeline extends StatelessWidget {
  const InvoiceTimeline({super.key, required this.invoice, required this.canManage});
  final InvoiceDetail invoice;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final summary = invoice.summary;
    final documents = <(DateTime, Widget)>[
      for (final receipt in invoice.receipts) (receipt.recordedAt, _receipt(context, receipt)),
      for (final refund in invoice.refunds) (refund.recordedAt, _refund(context, refund)),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    final VoidStamp? voided = invoice.voided;
    final rows = [
      InvoiceTimelineRow(
        icon: Icons.receipt_long_outlined,
        title: _t.created,
        subtitle: _t.byOn(summary.createdByName, Formatters.formatDateTime(summary.createdAt)),
      ),
      for (final (_, Widget row) in documents) row,
      if (voided != null)
        InvoiceTimelineRow(
          icon: Icons.block,
          title: _t.invoiceVoided,
          subtitle: _t.byOn(voided.byName, Formatters.formatDateTime(voided.at)),
          details: [_t.reasonLine(voided.reason)],
        ),
    ];
    return Material(
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(AppSizes.r12),
      ),
      child: Column(
        children: [
          for (final (index, row) in rows.indexed) ...[
            if (index > 0)
              Divider(
                height: AppSizes.borderWidth,
                thickness: AppSizes.borderWidth,
                color: colors.outlineVariant,
              ),
            row,
          ],
        ],
      ),
    );
  }

  Widget _receipt(BuildContext context, InvoiceReceipt receipt) {
    final VoidStamp? voided = receipt.voided;
    final bool locked = invoice.lockedByLaterRefund(receipt.recordedAt);
    return InvoiceTimelineRow(
      icon: receipt.method == PaymentMethod.cash ? Icons.payments_outlined : Icons.credit_card,
      title: _t.receipt(receipt.displayNumber),
      tag: voided != null
          ? _t.voided
          : receipt.replacesReceiptId != null
          ? _t.corrected
          : null,
      subtitle: [
        paymentMethodLabel(receipt.method),
        receipt.recordedByName,
        Formatters.formatDateTime(receipt.receivedAt),
      ].join(' · '),
      details: [
        if (voided != null) ...[
          _t.voidedBy(voided.byName, Formatters.formatDateTime(voided.at)),
          _t.reasonLine(voided.reason),
        ],
      ],
      amount: Money.format(receipt.amountMinor),
      voided: voided != null,
      menu: _menu(
        context,
        active: voided == null,
        locked: locked,
        canCorrect: true,
        onPrint: () => printInvoiceDocument(context, invoice, receipt: receipt),
        onCorrect: () => correctInvoiceReceipt(context, invoice, receipt),
        onVoid: () => voidInvoiceDocument(context, invoice, receipt: receipt),
      ),
    );
  }

  Widget _refund(BuildContext context, InvoiceRefund refund) {
    final VoidStamp? voided = refund.voided;
    final PaymentMethod? method = refund.paybackMethod;
    return InvoiceTimelineRow(
      icon: Icons.undo,
      title: _t.refundNumber(refund.displayNumber),
      tag: voided != null ? _t.voided : null,
      subtitle: _t.byOn(refund.recordedByName, Formatters.formatDateTime(refund.recordedAt)),
      details: [
        [
          _t.reducedBy(Money.format(refund.valueMinor)),
          if (refund.sessionsCancelled > 0) _t.sessionsCancelled(refund.sessionsCancelled),
        ].join(' · '),
        if (refund.paybackMinor == 0) _t.noPayback,
        _t.reasonLine(refund.reason),
        if (voided != null) ...[
          _t.voidedBy(voided.byName, Formatters.formatDateTime(voided.at)),
          _t.reasonLine(voided.reason),
        ],
      ],
      amount: refund.paybackMinor > 0 ? '− ${Money.format(refund.paybackMinor)}' : null,
      amountNote: method == null ? null : paymentMethodLabel(method),
      voided: voided != null,
      menu: _menu(
        context,
        active: voided == null,
        locked: invoice.lockedByLaterRefund(refund.recordedAt),
        canCorrect: false,
        onPrint: () => printInvoiceDocument(context, invoice, refund: refund),
        onVoid: () => voidInvoiceDocument(context, invoice, refund: refund),
      ),
    );
  }

  /// Print for everyone; Correct and Void for payment staff on active
  /// documents. A later refund locks both, and the menu says why.
  Widget _menu(
    BuildContext context, {
    required bool active,
    required bool locked,
    required bool canCorrect,
    required VoidCallback onPrint,
    required VoidCallback onVoid,
    VoidCallback? onCorrect,
  }) {
    final bool editable = canManage && active && !invoice.isVoided;
    String label(String action) => locked ? '$action\n${_t.lockedByRefund}' : action;
    return RecordActionMenu<_DocAction>(
      actions: [
        RecordMenuAction(_DocAction.print, _t.print, Icons.print_outlined),
        if (editable && canCorrect)
          RecordMenuAction(_DocAction.correct, label(_t.correct), Icons.edit_outlined, enabled: !locked),
        if (editable)
          RecordMenuAction(
            _DocAction.voidIt,
            label(_t.voidAction),
            Icons.block,
            destructive: !locked,
            enabled: !locked,
            dividerBefore: true,
          ),
      ],
      onSelected: (action) => switch (action) {
        _DocAction.print => onPrint(),
        _DocAction.correct => onCorrect?.call(),
        _DocAction.voidIt => onVoid(),
      },
    );
  }
}
