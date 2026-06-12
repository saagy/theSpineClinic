import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/payments/domain/clinic_package.dart';

/// Isolated layout fields for the RecordPaymentScreen form.
class PaymentFormFields extends StatefulWidget {
  /// Creates a [PaymentFormFields].
  const PaymentFormFields({
    super.key,
    required this.enabled,
    required this.packages,
    required this.formKey,
  });

  /// Whether form inputs are enabled.
  final bool enabled;

  /// Available packages retrieved from clinic settings.
  final List<ClinicPackage> packages;

  /// Global form key to modify field values dynamically.
  final GlobalKey<FormBuilderState> formKey;

  @override
  State<PaymentFormFields> createState() => _PaymentFormFieldsState();
}

class _PaymentFormFieldsState extends State<PaymentFormFields> {
  String? _selectedReasonType;

  InputDecoration _buildDecoration({required String labelText, String? hintText}) {
    final OutlineInputBorder borderBase = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r6)),
      borderSide: const BorderSide(color: AppColors.border, width: AppSizes.borderWidth),
    );

    return InputDecoration(
      labelText: labelText,
      labelStyle: AppTextStyles.captionMedium.copyWith(color: AppColors.textSecondary),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      isDense: true,
      filled: true,
      fillColor: widget.enabled ? AppColors.surface : AppColors.background,
      hintText: hintText,
      hintStyle: AppTextStyles.bodySecondary.copyWith(color: AppColors.textMuted),
      contentPadding: AppSizes.paddingCell,
      enabledBorder: borderBase,
      disabledBorder: borderBase,
      focusedBorder: borderBase.copyWith(
        borderSide: const BorderSide(color: AppColors.borderStrong, width: AppSizes.borderWidthFocused),
      ),
      errorBorder: borderBase.copyWith(
        borderSide: const BorderSide(color: AppColors.error, width: AppSizes.borderWidth),
      ),
      focusedErrorBorder: borderBase.copyWith(
        borderSide: const BorderSide(color: AppColors.error, width: AppSizes.borderWidthFocused),
      ),
      errorStyle: AppTextStyles.caption.copyWith(color: AppColors.error),
    );
  }

  void _handleReasonTypeChanged(String? type) {
    setState(() {
      _selectedReasonType = type;
    });

    // Clear conflicting fields based on reason type.
    if (type != 'Package') {
      widget.formKey.currentState?.fields['package']?.didChange(null);
    }
    if (type != 'Other') {
      widget.formKey.currentState?.fields['custom_reason']?.didChange(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPackageActive = _selectedReasonType == 'Package';
    final bool isOtherActive = _selectedReasonType == 'Other';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Quick-Select Reason Chips ──
        FormBuilderField<String>(
          name: 'reason_type',
          validator: FormBuilderValidators.required(errorText: AppStrings.reasonRequired),
          builder: (FormFieldState<String?> fieldState) {
            return InputDecorator(
              decoration: InputDecoration(
                labelText: AppStrings.paymentReason,
                labelStyle: AppTextStyles.captionMedium.copyWith(color: AppColors.textSecondary),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                border: InputBorder.none,
                errorText: fieldState.errorText,
                errorStyle: AppTextStyles.caption.copyWith(color: AppColors.error),
                contentPadding: EdgeInsets.zero,
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: AppSizes.p8),
                child: Wrap(
                  spacing: AppSizes.p8,
                  runSpacing: AppSizes.p4,
                  children: [
                    AppStrings.paymentReasonPackage,
                    AppStrings.paymentReasonSession,
                    AppStrings.paymentReasonGehaz,
                    AppStrings.paymentReasonOther,
                  ].map((type) {
                    final bool selected = fieldState.value == type;
                    return ChoiceChip(
                      label: Text(type),
                      selected: selected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      disabledColor: AppColors.background,
                      labelStyle: AppTextStyles.captionMedium.copyWith(
                        color: selected ? AppColors.textOnPrimary : AppColors.textSecondary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                        side: BorderSide(
                          color: selected ? AppColors.primary : AppColors.border,
                          width: AppSizes.borderWidth,
                        ),
                      ),
                      onSelected: widget.enabled
                          ? (bool val) {
                              fieldState.didChange(type);
                              _handleReasonTypeChanged(type);
                            }
                          : null,
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSizes.p24),

        // ── Dynamic Package Selection Dropdown ──
        if (isPackageActive) ...[
          FormBuilderDropdown<ClinicPackage>(
            name: 'package',
            enabled: widget.enabled,
            decoration: _buildDecoration(
              labelText: AppStrings.selectPackage,
              hintText: 'Choose clinic package',
            ),
            validator: isPackageActive
                ? FormBuilderValidators.required(errorText: 'Package selection is required')
                : null,
            items: widget.packages
                .map((pkg) => DropdownMenuItem<ClinicPackage>(
                      value: pkg,
                      child: Text('${pkg.name} (${pkg.price.toStringAsFixed(0)} EGP)'),
                    ))
                .toList(),
            onChanged: (ClinicPackage? pkg) {
              if (pkg != null) {
                widget.formKey.currentState?.fields['amount']?.didChange(pkg.price.toString());
              }
            },
          ),
          const SizedBox(height: AppSizes.p24),
        ],

        // ── Custom Reason Field ──
        if (isOtherActive) ...[
          FormBuilderTextField(
            name: 'custom_reason',
            enabled: widget.enabled,
            maxLines: 3,
            decoration: _buildDecoration(
              labelText: AppStrings.customReason,
              hintText: 'Enter custom payment description',
            ),
            validator: isOtherActive
                ? FormBuilderValidators.required(errorText: AppStrings.customReasonRequired)
                : null,
          ),
          const SizedBox(height: AppSizes.p24),
        ],

        // ── Amount Field ──
        FormBuilderTextField(
          name: 'amount',
          enabled: widget.enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _buildDecoration(
            labelText: AppStrings.paymentAmount,
            hintText: '0.00',
          ),
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(errorText: AppStrings.amountRequired),
            FormBuilderValidators.numeric(errorText: 'Must be a valid numeric value'),
            (String? val) {
              if (val != null) {
                final double? parsed = double.tryParse(val);
                if (parsed == null || parsed <= 0) {
                  return AppStrings.amountMustBePositive;
                }
              }
              return null;
            },
          ]),
        ),
      ],
    );
  }
}
