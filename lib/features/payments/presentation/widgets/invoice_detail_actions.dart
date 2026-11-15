import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/app_routes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/record_action_menu.dart';
import '../../../auth/domain/staff.dart';
import '../../domain/invoice_access.dart';
import '../../domain/invoice_action.dart';
import '../../domain/invoice_detail.dart';
import '../invoice_document_pdf.dart';
import 'invoice_cancel_paid_dialog.dart';
import 'invoice_payment_dialog.dart';
import 'invoice_void_dialog.dart';

const _t = AppStrings.invoiceDetail;
const _d = AppStrings.invoiceDiscount;

void _done(BuildContext context, bool? saved, String message) {
  if (saved == true && context.mounted) {
    AppSnackbar.show(context, message: message, variant: AppSnackbarVariant.success);
  }
}

Future<void> recordInvoicePayment(BuildContext context, InvoiceDetail invoice) async {
  final bool? saved = await showDialog<bool>(
    context: context,
    builder: (_) => InvoicePaymentDialog(invoice: invoice),
  );
  if (context.mounted) _done(context, saved, _t.paymentRecorded);
}

Future<void> correctInvoiceReceipt(
  BuildContext context,
  InvoiceDetail invoice,
  InvoiceReceipt receipt,
) async {
  final bool? saved = await showDialog<bool>(
    context: context,
    builder: (_) => InvoicePaymentDialog(invoice: invoice, correcting: receipt),
  );
  if (context.mounted) _done(context, saved, _t.receiptCorrected);
}

/// Voids the given receipt, refund or discount, or the invoice itself when
/// neither is passed. Every void asks for a reason first.
Future<void> voidInvoiceDocument(
  BuildContext context,
  InvoiceDetail invoice, {
  InvoiceReceipt? receipt,
  InvoiceRefund? refund,
}) async {
  final (String title, String help, String done) = receipt != null
      ? (
          _t.voidReceiptTitle,
          _t.voidReceiptHelp(Money.format(receipt.amountMinor)),
          _t.receiptVoided,
        )
      : refund != null && refund.isDiscount
      ? (_d.voidTitle, _d.voidHelp, _d.voided)
      : refund != null
      ? (_t.voidRefundTitle, _t.voidRefundHelp, _t.refundVoided)
      : (_t.voidInvoice, _t.voidInvoiceHelp, _t.invoiceVoidedDone);
  final bool? saved = await showDialog<bool>(
    context: context,
    builder: (_) => InvoiceVoidDialog(
      title: title,
      help: help,
      notice: receipt != null && takenBeforeToday(receipt.receivedAt)
          ? _t.pastDayCancelNotice(Formatters.formatDateMedium(receipt.receivedAt.toLocal()))
          : null,
      action: (reason) => receipt != null
          ? InvoiceAction.voidReceipt(invoice, receipt, reason)
          : refund != null
          ? InvoiceAction.voidRefund(invoice, refund, reason)
          : InvoiceAction.voidInvoice(invoice, reason),
    ),
  );
  if (context.mounted) _done(context, saved, done);
}

/// Cancels an invoice. A paid one first asks whether the money was given
/// back: if so the refund form opens; if it was entered by mistake the
/// invoice and its payments are cancelled together.
Future<void> cancelInvoice(BuildContext context, InvoiceDetail invoice) async {
  if (invoice.canVoid) return voidInvoiceDocument(context, invoice);
  final PaidInvoiceCancel? answer = await showDialog<PaidInvoiceCancel>(
    context: context,
    builder: (_) => InvoiceCancelPaidDialog(receivedMinor: invoice.receivedMinor),
  );
  if (!context.mounted || answer == null) return;
  if (answer == PaidInvoiceCancel.givenBack) return openInvoiceRefund(context, invoice);
  final bool? saved = await showDialog<bool>(
    context: context,
    builder: (_) => InvoiceVoidDialog(
      title: _t.voidInvoice,
      help: _t.cancelWithPaymentsHelp(Money.format(invoice.receivedMinor)),
      notice: switch (invoice.activeReceipts.where((r) => takenBeforeToday(r.receivedAt)).firstOrNull) {
        final InvoiceReceipt past => _t.pastDayInvoiceNotice(
          Formatters.formatDateMedium(past.receivedAt.toLocal()),
        ),
        null => null,
      },
      confirmLabel: _t.cancelWithPayments,
      action: (reason) => InvoiceAction.voidInvoiceWithPayments(invoice, reason),
    ),
  );
  if (context.mounted) _done(context, saved, _t.invoiceVoidedDone);
}

/// Opens the refund form; it returns `true` once a refund is recorded.
Future<void> openInvoiceRefund(BuildContext context, InvoiceDetail invoice) async {
  final bool? saved = await context.push<bool>(
    AppRoutes.invoiceRefundLocation(invoice.patientId, invoice.id),
  );
  if (context.mounted) _done(context, saved, _t.refundRecorded);
}

/// Opens the discount form; it returns `true` once a discount is recorded.
Future<void> openInvoiceDiscount(BuildContext context, InvoiceDetail invoice) async {
  final bool? saved = await context.push<bool>(
    AppRoutes.invoiceDiscountLocation(invoice.patientId, invoice.id),
  );
  if (context.mounted) _done(context, saved, _d.recorded);
}

Future<void> printInvoiceDocument(
  BuildContext context,
  InvoiceDetail invoice, {
  InvoiceReceipt? receipt,
  InvoiceRefund? refund,
}) async {
  final bool printed = await InvoiceDocumentPdf.print(invoice, receipt: receipt, refund: refund);
  if (!printed && context.mounted) {
    AppSnackbar.show(context, message: _t.printFailed, variant: AppSnackbarVariant.error);
  }
}

enum _InvoiceMenu { correct, voidIt }

/// App bar actions: Print for everyone, then Correct and Void for payment
/// staff. Actions that the invoice's state rules out stay listed with the
/// step that unlocks them.
class InvoiceAppBarActions extends StatelessWidget {
  const InvoiceAppBarActions({super.key, required this.invoice, required this.user});
  final InvoiceDetail invoice;
  final Staff user;

  bool get cancellable => invoice.canVoid || invoice.canVoidWithPayments;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        tooltip: _t.printInvoice,
        icon: const Icon(Icons.print_outlined, size: AppSizes.iconDefault),
        onPressed: () => printInvoiceDocument(context, invoice),
      ),
      if (InvoiceAccess.canManage(user) && !invoice.isVoided)
        RecordActionMenu<_InvoiceMenu>(
          actions: [
            RecordMenuAction(
              _InvoiceMenu.correct,
              invoice.canCorrect
                  ? _t.correctInvoice
                  : '${_t.correctInvoice}\n${_t.correctNeedsNoRefunds}',
              Icons.edit_outlined,
              enabled: invoice.canCorrect,
            ),
            RecordMenuAction(
              _InvoiceMenu.voidIt,
              cancellable ? _t.voidInvoice : '${_t.voidInvoice}\n${_t.voidNeedsNoRefunds}',
              Icons.block,
              destructive: cancellable,
              enabled: cancellable,
              dividerBefore: true,
            ),
          ],
          onSelected: (action) => switch (action) {
            _InvoiceMenu.correct => context.push(
              AppRoutes.invoiceCorrectLocation(invoice.patientId, invoice.id),
            ),
            _InvoiceMenu.voidIt => cancelInvoice(context, invoice),
          },
        ),
    ],
  );
}
