import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/clinic_colors.dart';
import '../../../../core/utils/money.dart';
import '../../domain/invoice_summary.dart';

const _t = AppStrings.invoices;

/// Amount due, money received and remaining sessions for one patient.
class InvoiceTotalsStrip extends StatelessWidget {
  const InvoiceTotalsStrip({
    super.key,
    required this.totals,
    required this.ptSessions,
    required this.tractionSessions,
  });
  final PatientInvoiceTotals? totals;
  final int ptSessions;
  final int tractionSessions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final int? due = totals?.dueMinor;
    final figures = [
      _Figure(_t.amountDue, due == null ? '–' : Money.format(due),
          due != null && due > 0 ? ClinicColors.of(context).warning : null),
      _Figure(_t.paid, totals == null ? '–' : Money.format(totals!.collectedMinor), null),
      _Figure(_t.ptSessionsLeft, '$ptSessions', null),
      _Figure(_t.tractionSessionsLeft, '$tractionSessions', null),
    ];
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(AppSizes.r12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: LayoutBuilder(
          builder: (context, box) {
            final bool large = MediaQuery.textScalerOf(context).scale(1) > 1.3;
            final bool wide = box.maxWidth >= AppSizes.invoiceTotalsWideBreakpoint && !large;
            final int perRow = wide ? 4 : large ? 1 : 2;
            return Column(
              children: [
                for (int start = 0; start < figures.length; start += perRow) ...[
                  if (start > 0) const SizedBox(height: AppSizes.p16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final figure in figures.skip(start).take(perRow))
                        Expanded(child: figure),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSizes.p4),
        Text(
          value,
          style: AppTextStyles.number.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    ),
  );
}
