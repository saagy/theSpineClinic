import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';

class PaymentLiveSummaryStrip extends StatelessWidget {
  const PaymentLiveSummaryStrip({
    super.key,
    required this.amount,
    required this.amountLabel,
    this.serviceTotal,
    this.remainingDue,
  });

  final double amount;
  final String amountLabel;
  final double? serviceTotal;
  final double? remainingDue;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double due = remainingDue ?? 0;
    final bool fullyPaid = amount > 0 && due <= 0 && serviceTotal != null;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p16,
        vertical: AppSizes.p8,
      ),
      decoration: BoxDecoration(
        color: fullyPaid ? cs.primaryContainer : cs.surfaceContainer,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryPart(
              label: amountLabel,
              value: amount.toCurrencyString(),
              color: fullyPaid ? cs.onPrimaryContainer : cs.onSurface,
            ),
          ),
          const SizedBox(width: AppSizes.p12),
          Expanded(
            child: _TrailingSummary(
              serviceTotal: serviceTotal,
              remainingDue: due,
              fullyPaid: fullyPaid,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrailingSummary extends StatelessWidget {
  const _TrailingSummary({
    required this.serviceTotal,
    required this.remainingDue,
    required this.fullyPaid,
  });

  final double? serviceTotal;
  final double remainingDue;
  final bool fullyPaid;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    if (fullyPaid) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.check_circle_rounded, color: cs.primary),
          const SizedBox(width: AppSizes.p6),
          Flexible(
            child: Text(
              AppStrings.paidInFull,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodyMedium.copyWith(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    }

    final String label = serviceTotal == null
        ? AppStrings.remainingDue
        : '${AppStrings.paymentSummaryOf} ${serviceTotal!.toCurrencyString()}';
    final String value = serviceTotal == null
        ? remainingDue.toCurrencyString()
        : '${AppStrings.remainingDue}: ${remainingDue.toCurrencyString()}';
    return _SummaryPart(
      label: label,
      value: value,
      color: remainingDue > 0 ? cs.error : cs.onSurface,
      alignEnd: true,
    );
  }
}

class _SummaryPart extends StatelessWidget {
  const _SummaryPart({
    required this.label,
    required this.value,
    required this.color,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: AppTextStyles.captionMedium.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSizes.p4),
        Text(
          value,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: AppTextStyles.bodyBold.copyWith(color: color),
        ),
      ],
    );
  }
}
