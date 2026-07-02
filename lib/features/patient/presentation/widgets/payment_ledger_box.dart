/// Structured financial breakdown sub-card for partial payments and package details.
///
/// Rule 1 — under 200 lines.
/// Rule 15/16 — Theme colorScheme and AppTextStyles.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/payments/domain/payment_record.dart';

/// Structured inner ledger container showing total price, remaining dues,
/// session additions, and the Collect Due button.
class PaymentLedgerBox extends StatelessWidget {
  const PaymentLedgerBox({
    super.key,
    required this.payment,
    required this.isAdmin,
    required this.onCollectDue,
  });

  final PaymentRecord payment;
  final bool isAdmin;
  final VoidCallback onCollectDue;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: AppSizes.p12),
      padding: const EdgeInsets.all(AppSizes.p12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSizes.r12),
        border: Border.all(
          color: cs.outlineVariant.withAlpha(128),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Package Session Credits (if any)
          if (payment.sessionBalanceAdded > 0 ||
              payment.tractionBalanceAdded > 0) ...[
            Wrap(
              spacing: AppSizes.p8,
              runSpacing: AppSizes.p6,
              children: [
                if (payment.sessionBalanceAdded > 0)
                  _TagChip(
                    label: '+${payment.sessionBalanceAdded} PT',
                    bg: cs.primaryContainer,
                    fg: cs.primary,
                  ),
                if (payment.tractionBalanceAdded > 0)
                  _TagChip(
                    label: '+${payment.tractionBalanceAdded} Tr',
                    bg: cs.secondaryContainer,
                    fg: cs.secondary,
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.p8),
          ],

          // Financial Breakdown Rows
          if (payment.totalPrice != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${AppStrings.serviceTotal}: ${payment.totalPrice!.toCurrencyString()}',
                  style: AppTextStyles.captionMedium.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${AppStrings.amountPaid}: ${payment.amount.toCurrencyString()}',
                  style: AppTextStyles.captionMedium.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],

          // Outstanding Due Info & Collect Button
          if (payment.hasOutstandingDue) ...[
            if (payment.totalPrice != null) const SizedBox(height: AppSizes.p8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.remainingDue,
                  style: AppTextStyles.captionMedium.copyWith(
                    color: cs.error,
                  ),
                ),
                Text(
                  payment.remainingDue.toCurrencyString(),
                  style: AppTextStyles.bodyBold.copyWith(
                    color: cs.error,
                  ),
                ),
              ],
            ),
            if (isAdmin) ...[
              const SizedBox(height: AppSizes.p8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onCollectDue,
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSizes.p8,
                    ),
                    minimumSize: const Size(double.infinity, 38),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(AppSizes.r8),
                      ),
                    ),
                  ),
                  icon: const Icon(
                    Icons.payments_outlined,
                    size: AppSizes.iconSmall,
                  ),
                  label: Text(
                    AppStrings.collectDue,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.bg, required this.fg});
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p8,
        vertical: AppSizes.p2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizes.r6),
      ),
      child: Text(
        label,
        style: AppTextStyles.captionBold.copyWith(
          color: fg,
        ),
      ),
    );
  }
}
