import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../auth/domain/staff.dart';
import '../../domain/invoice_access.dart';
import '../../domain/invoice_detail.dart';
import 'invoice_detail_actions.dart';
import 'invoice_detail_header.dart';
import 'invoice_detail_lines.dart';
import 'invoice_timeline.dart';

const _t = AppStrings.invoiceDetail;

/// Scrollable invoice content: identity and money first, then the services
/// behind the total, then everything that happened to it.
class InvoiceDetailBody extends StatelessWidget {
  const InvoiceDetailBody({super.key, required this.invoice, required this.user});
  final InvoiceDetail invoice;
  final Staff user;

  @override
  Widget build(BuildContext context) {
    final bool canManage = InvoiceAccess.canManage(user);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppSizes.p16, AppSizes.p8, AppSizes.p16, AppSizes.p32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.invoiceDetailMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InvoiceDetailHeader(invoice: invoice),
                const SizedBox(height: AppSizes.p16),
                InvoiceMoneyFigures(invoice: invoice),
                if (invoice.canRecordPayment || (canManage && invoice.canRefund)) ...[
                  const SizedBox(height: AppSizes.p16),
                  InvoicePrimaryActions(invoice: invoice, canManage: canManage),
                ],
                const SizedBox(height: AppSizes.p24),
                _Heading(_t.services),
                InvoiceDetailLines(invoice: invoice),
                const SizedBox(height: AppSizes.p24),
                _Heading(_t.activity),
                InvoiceTimeline(invoice: invoice, canManage: canManage),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSizes.p8),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: AppTextStyles.captionMedium.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  );
}

/// Record payment and Refund, shown only when each is possible.
class InvoicePrimaryActions extends StatelessWidget {
  const InvoicePrimaryActions({super.key, required this.invoice, required this.canManage});
  final InvoiceDetail invoice;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r8));
    const Size minimum = Size(AppSizes.tappableMin, AppSizes.tappableMin);
    return Wrap(
      spacing: AppSizes.p12,
      runSpacing: AppSizes.p8,
      children: [
        if (invoice.canRecordPayment)
          FilledButton.icon(
            onPressed: () => recordInvoicePayment(context, invoice),
            icon: const Icon(Icons.payments_outlined, size: AppSizes.iconSmall),
            label: Text(_t.recordPayment, style: AppTextStyles.bodyBold),
            style: FilledButton.styleFrom(minimumSize: minimum, shape: shape),
          ),
        if (canManage && invoice.canRefund)
          OutlinedButton.icon(
            onPressed: () => openInvoiceRefund(context, invoice),
            icon: const Icon(Icons.undo, size: AppSizes.iconSmall),
            label: Text(_t.refund, style: AppTextStyles.bodyBold),
            style: OutlinedButton.styleFrom(minimumSize: minimum, shape: shape),
          ),
      ],
    );
  }
}
