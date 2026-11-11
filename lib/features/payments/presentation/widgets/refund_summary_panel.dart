import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/clinic_colors.dart';
import '../../../../core/utils/money.dart';
import '../../domain/invoice_action.dart';
import '../../domain/service_catalog_item.dart';

const _t = AppStrings.invoiceDetail;
const _i = AppStrings.invoices;

/// Live outcome of the refund for review: the new invoice value, the money to
/// hand back, what stays due and the sessions leaving the balance.
class RefundSummaryPanel extends StatelessWidget {
  const RefundSummaryPanel({super.key, required this.draft});
  final RefundDraft draft;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final int pt = draft.sessionsOf(ServiceType.ptSession);
    final int traction = draft.sessionsOf(ServiceType.tractionSession);
    final int due = draft.dueAfterMinor;
    // An over-typed value is reported on its field; keep the preview sane.
    final int newValue = draft.newValueMinor < 0 ? 0 : draft.newValueMinor;
    return Semantics(
      container: true,
      label: _t.refundSummary,
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
              Text(_t.refundSummary, style: AppTextStyles.headingSmall),
              const SizedBox(height: AppSizes.p16),
              _Line(_t.currentValue, Money.format(draft.invoice.valueMinor)),
              _Line(_t.refundTitle, '− ${Money.format(draft.refundValueMinor)}'),
              const Divider(height: AppSizes.p24),
              _Line(_t.newValue, Money.format(newValue), strong: true),
              _Line(_t.paid, Money.format(draft.invoice.collectedMinor)),
              const Divider(height: AppSizes.p24),
              _Line(_t.payBack, Money.format(draft.paybackMinor), strong: true),
              _Line(
                _t.leftToPay,
                Money.format(due < 0 ? 0 : due),
                strong: true,
                color: due > 0 ? ClinicColors.of(context).warning : null,
              ),
              if (pt > 0 || traction > 0) ...[
                const Divider(height: AppSizes.p24),
                Text(
                  _t.sessionsRemoved,
                  style: AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSizes.p4),
                if (pt > 0) Text(_i.ptSessions(pt), style: AppTextStyles.bodyMedium),
                if (traction > 0) Text(_i.tractionSessions(traction), style: AppTextStyles.bodyMedium),
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
