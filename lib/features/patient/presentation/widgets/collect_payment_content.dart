import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/payment_live_summary_strip.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/payment_mode_selector.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/payment_package_credit_section.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/payment_reason_section.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/payment_text_field.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';

class CollectPaymentContent extends StatelessWidget {
  const CollectPaymentContent({
    super.key,
    required this.scrollController,
    required this.amountCtrl,
    required this.totalPriceCtrl,
    required this.reasonCtrl,
    required this.sessionCtrl,
    required this.tractionCtrl,
    required this.amountFocus,
    required this.reason,
    required this.reasonPresets,
    required this.isPartial,
    required this.addToPackage,
    required this.isAssessment,
    required this.submitting,
    required this.onPartialChanged,
    required this.onReasonChanged,
    required this.onPackageChanged,
    required this.onSubmit,
  });

  final ScrollController? scrollController;
  final TextEditingController amountCtrl;
  final TextEditingController totalPriceCtrl;
  final TextEditingController reasonCtrl;
  final TextEditingController sessionCtrl;
  final TextEditingController tractionCtrl;
  final FocusNode amountFocus;
  final String reason;
  final List<String> reasonPresets;
  final bool isPartial;
  final bool addToPackage;
  final bool isAssessment;
  final bool submitting;
  final ValueChanged<bool> onPartialChanged;
  final ValueChanged<String> onReasonChanged;
  final ValueChanged<bool> onPackageChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final double amount = double.tryParse(amountCtrl.text) ?? 0;
    final double serviceTotal = isPartial
        ? (double.tryParse(totalPriceCtrl.text) ?? 0)
        : amount;
    final double remainingDue = isPartial ? serviceTotal - amount : 0;
    final String buttonLabel = amount > 0
        ? AppStrings.recordPaymentCta(amount.toCurrencyString())
        : AppStrings.confirmPayment;

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
                  Row(
                    children: [
                      Expanded(
                        child: PaymentTextField(
                          controller: totalPriceCtrl,
                          labelText: AppStrings.serviceTotal,
                          hintText: AppStrings.zeroAmountHint,
                          suffixText: AppStrings.currencyEgp,
                          enabled: !submitting,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.p12),
                      Expanded(
                        child: PaymentTextField(
                          controller: amountCtrl,
                          focusNode: amountFocus,
                          labelText: AppStrings.amountPaidNow,
                          hintText: AppStrings.zeroAmountHint,
                          suffixText: AppStrings.currencyEgp,
                          enabled: !submitting,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  PaymentTextField(
                    controller: amountCtrl,
                    focusNode: amountFocus,
                    labelText: AppStrings.amountPaidNow,
                    hintText: AppStrings.zeroAmountHint,
                    suffixText: AppStrings.currencyEgp,
                    enabled: !submitting,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ],
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
                    labelText: AppStrings.customReason,
                    hintText: AppStrings.customReasonHint,
                    enabled: !submitting,
                    maxLines: 2,
                  ),
                ],
                const SizedBox(height: AppSizes.p24),
                PaymentPackageCreditSection(
                  addToPackage: addToPackage,
                  isAssessment: isAssessment,
                  enabled: !submitting,
                  onChanged: onPackageChanged,
                  sessionController: sessionCtrl,
                  tractionController: tractionCtrl,
                ),
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
                amountLabel: AppStrings.amountPaidNow,
                serviceTotal: serviceTotal,
                remainingDue: remainingDue,
              ),
              const SizedBox(height: AppSizes.p12),
              AppButton(
                labelText: buttonLabel,
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
