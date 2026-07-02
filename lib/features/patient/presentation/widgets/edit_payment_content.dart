import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/payment_live_summary_strip.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/payment_mode_selector.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/payment_reason_section.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/payment_text_field.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';

class EditPaymentContent extends StatelessWidget {
  const EditPaymentContent({
    super.key,
    required this.scrollController,
    required this.amountCtrl,
    required this.totalPriceCtrl,
    required this.reasonCtrl,
    required this.amountFocus,
    required this.totalFocus,
    required this.reasonFocus,
    required this.reason,
    required this.reasonPresets,
    required this.isPartial,
    required this.submitting,
    required this.onPartialChanged,
    required this.onReasonChanged,
    required this.onSubmit,
  });

  final ScrollController? scrollController;
  final TextEditingController amountCtrl;
  final TextEditingController totalPriceCtrl;
  final TextEditingController reasonCtrl;
  final FocusNode amountFocus;
  final FocusNode totalFocus;
  final FocusNode reasonFocus;
  final String reason;
  final List<String> reasonPresets;
  final bool isPartial;
  final bool submitting;
  final ValueChanged<bool> onPartialChanged;
  final ValueChanged<String> onReasonChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final double amount = double.tryParse(amountCtrl.text) ?? 0;
    final double total = isPartial
        ? (double.tryParse(totalPriceCtrl.text) ?? 0)
        : amount;
    final double due = isPartial ? total - amount : 0;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PaymentModeSelector(
                  isPartial: isPartial,
                  enabled: !submitting,
                  onChanged: onPartialChanged,
                ),
                const SizedBox(height: AppSizes.p16),
                if (isPartial) ...[
                  PaymentTextField(
                    controller: totalPriceCtrl,
                    focusNode: totalFocus,
                    labelText: AppStrings.serviceTotal,
                    hintText: AppStrings.zeroAmountHint,
                    suffixText: AppStrings.currencyEgp,
                    enabled: !submitting,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: AppSizes.p16),
                ],
                PaymentTextField(
                  controller: amountCtrl,
                  focusNode: amountFocus,
                  labelText: AppStrings.amountPaidSoFar,
                  hintText: AppStrings.zeroAmountHint,
                  suffixText: AppStrings.currencyEgp,
                  enabled: !submitting,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: AppSizes.p24),
                PaymentReasonSection(
                  options: reasonPresets,
                  selected: reason,
                  enabled: !submitting,
                  onChanged: onReasonChanged,
                ),
                if (reason == AppStrings.paymentReasonOther) ...[
                  const SizedBox(height: AppSizes.p16),
                  PaymentTextField(
                    controller: reasonCtrl,
                    focusNode: reasonFocus,
                    labelText: AppStrings.customReason,
                    hintText: AppStrings.customReasonHint,
                    enabled: !submitting,
                    maxLines: 2,
                  ),
                ],
                const SizedBox(height: AppSizes.p24),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.p24,
            AppSizes.p12,
            AppSizes.p24,
            AppSizes.p16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PaymentLiveSummaryStrip(
                amount: amount,
                amountLabel: AppStrings.amountPaidSoFar,
                serviceTotal: total,
                remainingDue: due,
              ),
              const SizedBox(height: AppSizes.p12),
              AppButton(
                labelText: AppStrings.saveChanges,
                isLoading: submitting,
                onPressed: onSubmit,
                debounceMs: 1000,
                shape: AppButtonShape.pill,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
