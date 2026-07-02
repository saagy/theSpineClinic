import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/payments/domain/clinic_package.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/payment_input_decoration.dart';

class PaymentFormPackageDropdown extends StatelessWidget {
  const PaymentFormPackageDropdown({
    super.key,
    required this.enabled,
    required this.packages,
    required this.onChanged,
  });

  final bool enabled;
  final List<ClinicPackage> packages;
  final ValueChanged<ClinicPackage> onChanged;

  @override
  Widget build(BuildContext context) {
    return FormBuilderDropdown<ClinicPackage>(
      name: 'package',
      enabled: enabled,
      decoration: paymentInputDecoration(
        context,
        labelText: AppStrings.selectPackage,
        hintText: AppStrings.chooseClinicPackage,
      ),
      validator: FormBuilderValidators.required(
        errorText: AppStrings.packageSelectionRequired,
      ),
      items: packages
          .map(
            (pkg) => DropdownMenuItem<ClinicPackage>(
              value: pkg,
              child: Text('${pkg.name} (${pkg.price.toCurrencyString()})'),
            ),
          )
          .toList(),
      onChanged: (ClinicPackage? pkg) {
        if (pkg != null) onChanged(pkg);
      },
    );
  }
}

class PaymentFormBalanceSection extends StatelessWidget {
  const PaymentFormBalanceSection({
    super.key,
    required this.enabled,
    required this.isAssessment,
    required this.addToPackage,
    required this.onChanged,
    required this.validateAddedInt,
  });

  final bool enabled;
  final bool isAssessment;
  final bool addToPackage;
  final ValueChanged<bool> onChanged;
  final String? Function(String?) validateAddedInt;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppSizes.borderRadiusCard,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          FormBuilderField<bool>(
            name: 'add_to_package',
            initialValue: addToPackage,
            builder: (FormFieldState<bool?> fieldState) {
              final bool value = (fieldState.value ?? false) && !isAssessment;
              return Row(
                children: [
                  Expanded(child: _BalanceCopy(isAssessment: isAssessment)),
                  Switch.adaptive(
                    value: value,
                    onChanged: enabled && !isAssessment
                        ? (bool next) {
                            fieldState.didChange(next);
                            onChanged(next);
                          }
                        : null,
                  ),
                ],
              );
            },
          ),
          if (addToPackage && !isAssessment) ...[
            const SizedBox(height: AppSizes.p16),
            Row(
              children: [
                Expanded(
                  child: FormBuilderTextField(
                    name: 'session_added',
                    enabled: enabled,
                    keyboardType: TextInputType.number,
                    decoration: paymentInputDecoration(
                      context,
                      labelText: AppStrings.sessionBalanceAddedField,
                      hintText: AppStrings.leaveEmptyToSkip,
                    ),
                    validator: validateAddedInt,
                  ),
                ),
                const SizedBox(width: AppSizes.p12),
                Expanded(
                  child: FormBuilderTextField(
                    name: 'traction_added',
                    enabled: enabled,
                    keyboardType: TextInputType.number,
                    decoration: paymentInputDecoration(
                      context,
                      labelText: AppStrings.tractionBalanceAddedField,
                      hintText: AppStrings.leaveEmptyToSkip,
                    ),
                    validator: validateAddedInt,
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

class _BalanceCopy extends StatelessWidget {
  const _BalanceCopy({required this.isAssessment});

  final bool isAssessment;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.addBalanceToggleTitle,
          style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
        ),
        const SizedBox(height: AppSizes.p4),
        Text(
          isAssessment
              ? AppStrings.addBalanceAssessmentDisabled
              : AppStrings.addBalanceBothZero,
          style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}
