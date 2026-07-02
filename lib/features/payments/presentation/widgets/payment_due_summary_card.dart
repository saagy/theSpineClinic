import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/payments/domain/payment_record.dart';

class PaymentDueSummaryCard extends StatelessWidget {
  const PaymentDueSummaryCard({super.key, required this.payment});

  final PaymentRecord payment;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double serviceTotal = payment.totalPrice ?? payment.amount;

    return Container(
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppSizes.borderRadiusCard,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            payment.reason,
            style: AppTextStyles.bodyBold.copyWith(color: cs.onSurface),
          ),
          const SizedBox(height: AppSizes.p16),
          _MoneyRow(
            label: AppStrings.serviceTotal,
            value: serviceTotal.toCurrencyString(),
          ),
          const SizedBox(height: AppSizes.p8),
          _MoneyRow(
            label: AppStrings.amountPaidSoFar,
            value: payment.amount.toCurrencyString(),
          ),
          const SizedBox(height: AppSizes.p8),
          _MoneyRow(
            label: AppStrings.remainingDue,
            value: payment.remainingDue.toCurrencyString(),
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.captionMedium.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyBold.copyWith(
            color: emphasized ? cs.error : cs.onSurface,
          ),
        ),
      ],
    );
  }
}
