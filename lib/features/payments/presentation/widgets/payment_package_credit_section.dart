import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/payment_text_field.dart';

class PaymentPackageCreditSection extends StatelessWidget {
  const PaymentPackageCreditSection({
    super.key,
    required this.addToPackage,
    required this.isAssessment,
    required this.enabled,
    required this.onChanged,
    required this.sessionController,
    required this.tractionController,
  });

  final bool addToPackage;
  final bool isAssessment;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final TextEditingController sessionController;
  final TextEditingController tractionController;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool canEdit = enabled && !isAssessment;
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.addBalanceToggleTitle,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSizes.p4),
                    Text(
                      isAssessment
                          ? AppStrings.addBalanceAssessmentDisabled
                          : AppStrings.addBalanceBothZero,
                      style: AppTextStyles.caption.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: addToPackage && !isAssessment,
                onChanged: canEdit ? onChanged : null,
              ),
            ],
          ),
          if (addToPackage && !isAssessment) ...[
            const SizedBox(height: AppSizes.p16),
            Row(
              children: [
                Expanded(
                  child: PaymentTextField(
                    controller: sessionController,
                    enabled: enabled,
                    labelText: AppStrings.sessionBalanceAddedField,
                    hintText: AppStrings.leaveEmptyToSkip,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: AppSizes.p12),
                Expanded(
                  child: PaymentTextField(
                    controller: tractionController,
                    enabled: enabled,
                    labelText: AppStrings.tractionBalanceAddedField,
                    hintText: AppStrings.leaveEmptyToSkip,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
