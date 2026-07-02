import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/payment_input_decoration.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/payment_live_summary_strip.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/payment_mode_selector.dart';

class PaymentFormAmountSection extends StatelessWidget {
  const PaymentFormAmountSection({
    super.key,
    required this.formKey,
    required this.enabled,
    required this.isPartial,
    required this.onPartialChanged,
    required this.onFieldChanged,
  });

  final GlobalKey<FormBuilderState> formKey;
  final bool enabled;
  final bool isPartial;
  final ValueChanged<bool> onPartialChanged;
  final VoidCallback onFieldChanged;

  @override
  Widget build(BuildContext context) {
    final double amount = _fieldAmount('amount');
    final double total = _fieldAmount('total_price');
    final double due = isPartial ? total - amount : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormBuilderField<bool>(
          name: 'is_partial',
          initialValue: isPartial,
          builder: (FormFieldState<bool?> fieldState) {
            return PaymentModeSelector(
              isPartial: fieldState.value ?? false,
              enabled: enabled,
              onChanged: (bool next) {
                fieldState.didChange(next);
                onPartialChanged(next);
              },
            );
          },
        ),
        const SizedBox(height: AppSizes.p16),
        if (isPartial) ...[
          FormBuilderTextField(
            name: 'total_price',
            enabled: enabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: paymentInputDecoration(
              context,
              labelText: AppStrings.serviceTotal,
              hintText: AppStrings.zeroAmountHint,
              suffixText: AppStrings.currencyEgp,
            ),
            onChanged: (_) => onFieldChanged(),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(
                errorText: AppStrings.totalAmountRequired,
              ),
              FormBuilderValidators.numeric(
                errorText: AppStrings.validNumericAmount,
              ),
              _positiveTotal,
            ]),
          ),
          const SizedBox(height: AppSizes.p16),
        ],
        FormBuilderTextField(
          name: 'amount',
          enabled: enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: paymentInputDecoration(
            context,
            labelText: isPartial
                ? AppStrings.amountPaidNow
                : AppStrings.paymentAmount,
            hintText: AppStrings.zeroAmountHint,
            suffixText: AppStrings.currencyEgp,
          ),
          onChanged: (_) => onFieldChanged(),
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(
              errorText: AppStrings.amountRequired,
            ),
            FormBuilderValidators.numeric(
              errorText: AppStrings.validNumericAmount,
            ),
            _positiveAmount,
            _notAboveTotal,
          ]),
        ),
        if (isPartial) ...[
          const SizedBox(height: AppSizes.p16),
          PaymentLiveSummaryStrip(
            amount: amount,
            amountLabel: AppStrings.amountPaidNow,
            serviceTotal: total,
            remainingDue: due,
          ),
        ],
      ],
    );
  }

  double _fieldAmount(String name) {
    final Object? value = formKey.currentState?.fields[name]?.value;
    if (value is String) return double.tryParse(value) ?? 0;
    if (value is num) return value.toDouble();
    return 0;
  }

  String? _positiveTotal(String? value) {
    final double? parsed = double.tryParse(value ?? '');
    if (parsed == null || parsed <= 0) return AppStrings.totalAmountPositive;
    return null;
  }

  String? _positiveAmount(String? value) {
    final double? parsed = double.tryParse(value ?? '');
    if (parsed == null || parsed <= 0) return AppStrings.amountMustBePositive;
    return null;
  }

  String? _notAboveTotal(String? value) {
    if (!isPartial) return null;
    final double? amount = double.tryParse(value ?? '');
    final double total = _fieldAmount('total_price');
    if (amount != null && total > 0 && amount > total) {
      return AppStrings.amountExceedsServiceTotal;
    }
    return null;
  }
}
