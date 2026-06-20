import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/payments/domain/clinic_package.dart';
import 'package:spine_clinic_app/shared/widgets/reason_chips_row.dart';

/// Isolated layout fields for the RecordPaymentScreen form.
///
/// Renders one of four reason presets per row plus a "Package" path that
/// auto-fills both PT + traction adders from the selected clinic package.
class PaymentFormFields extends StatefulWidget {
  /// Creates a [PaymentFormFields].
  const PaymentFormFields({
    required this.enabled,
    required this.packages,
    required this.formKey,
    super.key,
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
  bool _addToPackage = false;

  bool _isAssessment(String? reason) =>
      reason == AppStrings.paymentReasonInitialAssessment ||
      reason == AppStrings.paymentReasonReassessment;

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
      // Toggle rule:
      //   'Package'        → ON (clerks want to credit the patient's buckets
      //                       immediately when selling a package)
      //   assessments      → hidden entirely (handled in build())
      //   any other reason → OFF (the receptionist has to opt in explicitly)
      _addToPackage = !_isAssessment(type) && type == AppStrings.paymentReasonPackage;
    });

    if (type != AppStrings.paymentReasonPackage) {
      widget.formKey.currentState?.fields['package']?.didChange(null);
    }
    if (type != AppStrings.paymentReasonOther) {
      widget.formKey.currentState?.fields['custom_reason']?.didChange(null);
    }
    if (_isAssessment(type)) {
      widget.formKey.currentState?.fields['session_added']?.didChange('0');
      widget.formKey.currentState?.fields['traction_added']?.didChange('0');
    }
    // Mirror the new toggle value into the form's stored payload so _submit
    // sees the right boolean regardless of which reason the user picked.
    widget.formKey.currentState?.fields['add_to_package']
        ?.didChange(_addToPackage);
  }

  /// Decides which adders the current "Package" selection populates.
  void _seedAddersFromPackage(ClinicPackage pkg) {
    widget.formKey.currentState?.fields['amount']?.didChange(pkg.price.toString());
    if (pkg.kind.creditsSessionBalance) {
      widget.formKey.currentState?.fields['session_added']
          ?.didChange(pkg.sessionCount.toString());
    } else {
      widget.formKey.currentState?.fields['session_added']?.didChange('0');
    }
    if (pkg.kind.creditsTractionBalance) {
      widget.formKey.currentState?.fields['traction_added']
          ?.didChange(pkg.tractionsCount.toString());
    } else {
      widget.formKey.currentState?.fields['traction_added']?.didChange('0');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPackageActive = _selectedReasonType == AppStrings.paymentReasonPackage;
    final bool isOtherActive = _selectedReasonType == AppStrings.paymentReasonOther;
    final bool isAssessment = _isAssessment(_selectedReasonType);

    const List<String> reasonPresets = [
      AppStrings.paymentReasonPackage,
      AppStrings.paymentReasonNormalPtSession,
      AppStrings.paymentReasonSpinalTraction,
      AppStrings.paymentReasonInitialAssessment,
      AppStrings.paymentReasonReassessment,
      AppStrings.paymentReasonOther,
    ];

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
                child: ReasonChipsRow(
                  options: reasonPresets,
                  selected: fieldState.value,
                  enabled: widget.enabled,
                  onChanged: (type) {
                    fieldState.didChange(type);
                    _handleReasonTypeChanged(type);
                  },
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSizes.p24),

        // ── Package Selection (dropdown only for "Package" reason) ──
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
              if (pkg != null) _seedAddersFromPackage(pkg);
            },
          ),
          const SizedBox(height: AppSizes.p16),
        ],

        // ── Add to package balances (hidden for assessments) ──
        if (!isAssessment) ...[
          FormBuilderField<bool>(
            name: 'add_to_package',
            initialValue: _addToPackage,
            builder: (FormFieldState<bool?> fieldState) {
              return SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  AppStrings.addBalanceToggleTitle,
                  style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                ),
                subtitle: Text(
                  AppStrings.addBalanceBothZero,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                ),
                value: fieldState.value ?? false,
                onChanged: widget.enabled
                    ? (bool v) {
                        fieldState.didChange(v);
                        setState(() => _addToPackage = v);
                      }
                    : null,
              );
            },
          ),
          const SizedBox(height: AppSizes.p4),
          Text(
            AppStrings.addBalanceBothZero,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSizes.p8),
          if (_addToPackage) ...[
            Row(
              children: [
                Expanded(
                  child: FormBuilderTextField(
                    name: 'session_added',
                    enabled: widget.enabled,
                    keyboardType: TextInputType.number,
                    decoration: _buildDecoration(
                      labelText: AppStrings.sessionBalanceAddedField,
                      hintText: 'Leave empty to skip',
                    ),
                    validator: _validateAddedInt,
                  ),
                ),
                const SizedBox(width: AppSizes.p12),
                Expanded(
                  child: FormBuilderTextField(
                    name: 'traction_added',
                    enabled: widget.enabled,
                    keyboardType: TextInputType.number,
                    decoration: _buildDecoration(
                      labelText: AppStrings.tractionBalanceAddedField,
                      hintText: 'Leave empty to skip',
                    ),
                    validator: _validateAddedInt,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.p16),
          ],
        ],

        // ── Custom Reason ──
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

  /// Empty fields mean "don't touch this bucket" — only reject when the
  /// receptionist typed something invalid. Keeps the standard contract
  /// for FormBuilder while matching the package UX rule.
  String? _validateAddedInt(String? val) {
    if (val == null || val.isEmpty) return null;
    final int? parsed = int.tryParse(val);
    if (parsed == null || parsed < 0) {
      return AppStrings.amountMustBePositive;
    }
    return null;
  }
}
