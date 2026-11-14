import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/clinic_colors.dart';
import '../../../../core/utils/money.dart';
import '../../domain/invoice_action.dart';
import '../../domain/service_catalog_item.dart';

const _t = AppStrings.invoiceDetail;
const _d = AppStrings.invoiceDiscount;
const _i = AppStrings.invoices;

/// Live outcome of the refund for review: the new invoice value, the money to
/// hand back, what stays due and the sessions leaving the balance.
class RefundSummaryPanel extends StatelessWidget {
  const RefundSummaryPanel({super.key, required this.draft});
  final RefundDraft draft;

  @override
  Widget build(BuildContext context) => ReductionSummaryPanel(
    title: _t.refundSummary,
    reductionLabel: _t.refundTitle,
    currentMinor: draft.invoice.valueMinor,
    reductionMinor: draft.refundValueMinor,
    newValueMinor: draft.newValueMinor,
    paidMinor: draft.invoice.collectedMinor,
    paybackMinor: draft.paybackMinor,
    dueMinor: draft.dueAfterMinor,
    ptSessions: draft.sessionsOf(ServiceType.ptSession),
    tractionSessions: draft.sessionsOf(ServiceType.tractionSession),
  );
}

/// Live outcome of a discount: the same figures as a refund, without sessions.
class DiscountSummaryPanel extends StatelessWidget {
  const DiscountSummaryPanel({super.key, required this.draft});
  final DiscountDraft draft;

  @override
  Widget build(BuildContext context) => ReductionSummaryPanel(
    title: _d.summary,
    reductionLabel: _d.title,
    currentMinor: draft.invoice.valueMinor,
    reductionMinor: draft.discountMinor,
    newValueMinor: draft.newValueMinor,
    paidMinor: draft.invoice.collectedMinor,
    paybackMinor: draft.paybackMinor,
    dueMinor: draft.dueAfterMinor,
  );
}

/// Invoice value now, the reduction, the new value, what is paid back and
/// what is left to pay. Over-typed values are reported on their fields, so
/// the preview keeps every figure at zero or above.
class ReductionSummaryPanel extends StatelessWidget {
  const ReductionSummaryPanel({
    super.key,
    required this.title,
    required this.reductionLabel,
    required this.currentMinor,
    required this.reductionMinor,
    required this.newValueMinor,
    required this.paidMinor,
    required this.paybackMinor,
    required this.dueMinor,
    this.ptSessions = 0,
    this.tractionSessions = 0,
  });
  final String title;
  final String reductionLabel;
  final int currentMinor;
  final int reductionMinor;
  final int newValueMinor;
  final int paidMinor;
  final int paybackMinor;
  final int dueMinor;
  final int ptSessions;
  final int tractionSessions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    String money(int minor) => Money.format(minor < 0 ? 0 : minor);
    return Semantics(
      container: true,
      label: title,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(AppSizes.r12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: AppTextStyles.headingSmall),
              const SizedBox(height: AppSizes.p16),
              _Line(_t.currentValue, Money.format(currentMinor)),
              _Line(reductionLabel, '− ${money(reductionMinor)}'),
              const Divider(height: AppSizes.p24),
              _Line(_t.newValue, money(newValueMinor), strong: true),
              _Line(_t.paid, Money.format(paidMinor)),
              const Divider(height: AppSizes.p24),
              _Line(_t.payBack, Money.format(paybackMinor), strong: true),
              _Line(
                _t.leftToPay,
                money(dueMinor),
                strong: true,
                color: dueMinor > 0 ? ClinicColors.of(context).warning : null,
              ),
              if (ptSessions > 0 || tractionSessions > 0) ...[
                const Divider(height: AppSizes.p24),
                Text(
                  _t.sessionsRemoved,
                  style: AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSizes.p4),
                if (ptSessions > 0) Text(_i.ptSessions(ptSessions), style: AppTextStyles.bodyMedium),
                if (tractionSessions > 0)
                  Text(_i.tractionSessions(tractionSessions), style: AppTextStyles.bodyMedium),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.strong = false, this.color});
  final String label;
  final String value;
  final bool strong;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSizes.p4),
    child: MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: strong ? AppTextStyles.bodyBold : AppTextStyles.body)),
          const SizedBox(width: AppSizes.p12),
          Text(
            value,
            style: AppTextStyles.number.copyWith(
              fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
              color: color ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    ),
  );
}
