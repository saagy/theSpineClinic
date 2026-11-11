import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/clinic_colors.dart';
import '../../../../core/utils/money.dart';
import '../../domain/invoice_draft.dart';
import '../../domain/service_catalog_item.dart';

const _t = AppStrings.invoices;

/// Live totals for review before the invoice is created.
class InvoiceSummaryPanel extends StatelessWidget {
  const InvoiceSummaryPanel({super.key, required this.draft});
  final InvoiceDraft draft;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final int pt = draft.sessionsOf(ServiceType.ptSession);
    final int traction = draft.sessionsOf(ServiceType.tractionSession);
    final int due = draft.dueAfterMinor;
    return Semantics(
      container: true,
      label: _t.summary,
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
              Text(_t.summary, style: AppTextStyles.headingSmall),
              const SizedBox(height: AppSizes.p16),
              _Line(_t.subtotal, Money.format(draft.subtotalMinor)),
              if (draft.discountMinor > 0) _Line(_t.discount, '− ${Money.format(draft.discountMinor)}'),
              const Divider(height: AppSizes.p24),
              _Line(_t.total, Money.format(draft.totalMinor), strong: true),
              if (draft.paidNowMinor > 0) _Line(_t.paidNow, Money.format(draft.paidNowMinor)),
              _Line(
                _t.dueAfter,
                Money.format(due < 0 ? 0 : due),
                strong: true,
                color: due > 0 ? ClinicColors.of(context).warning : null,
              ),
              if (pt > 0 || traction > 0) ...[
                const Divider(height: AppSizes.p24),
                Text(
                  _t.sessionsAdded,
                  style: AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSizes.p4),
                if (pt > 0) Text(_t.ptSessions(pt), style: AppTextStyles.bodyMedium),
                if (traction > 0) Text(_t.tractionSessions(traction), style: AppTextStyles.bodyMedium),
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
