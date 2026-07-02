import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/shared/widgets/reason_chips_row.dart';

class PaymentReasonSection extends StatelessWidget {
  const PaymentReasonSection({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
    this.errorText,
  });

  final List<String> options;
  final String? selected;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.paymentReason,
          style: AppTextStyles.captionMedium.copyWith(
            color: errorText == null ? cs.onSurfaceVariant : cs.error,
          ),
        ),
        const SizedBox(height: AppSizes.p8),
        ReasonChipsRow(
          options: options,
          selected: selected,
          enabled: enabled,
          onChanged: onChanged,
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSizes.p6),
          Text(
            errorText!,
            style: AppTextStyles.caption.copyWith(color: cs.error),
          ),
        ],
      ],
    );
  }
}
