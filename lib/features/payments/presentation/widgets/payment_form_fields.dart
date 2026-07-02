import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/payments/domain/clinic_package.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/payment_form_amount_section.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/payment_form_package_section.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/payment_input_decoration.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/payment_reason_section.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/payment_reason_presets.dart';

class PaymentFormFields extends StatefulWidget {
  const PaymentFormFields({
    required this.enabled,
    required this.packages,
    required this.formKey,
    super.key,
  });

  final bool enabled;
  final List<ClinicPackage> packages;
  final GlobalKey<FormBuilderState> formKey;

  @override
  State<PaymentFormFields> createState() => _PaymentFormFieldsState();
}

class _PaymentFormFieldsState extends State<PaymentFormFields> {
  String? _selectedReasonType;
  bool _addToPackage = false;
  bool _isPartial = false;
  String _lastTotalPrice = '';

  bool _isAssessment(String? reason) =>
      reason == AppStrings.paymentReasonInitialAssessment ||
      reason == AppStrings.paymentReasonReassessment;

  void _handleReasonChanged(String type) {
    setState(() {
      _selectedReasonType = type;
      _addToPackage =
          !_isAssessment(type) && type == AppStrings.paymentReasonPackage;
    });
    final fields = widget.formKey.currentState?.fields;
    fields?['add_to_package']?.didChange(_addToPackage);
    if (type != AppStrings.paymentReasonPackage) {
      fields?['package']?.didChange(null);
    }
    if (type != AppStrings.paymentReasonOther) {
      fields?['custom_reason']?.didChange(null);
    }
    if (_isAssessment(type)) {
      fields?['session_added']?.didChange('0');
      fields?['traction_added']?.didChange('0');
    }
  }

  void _seedAddersFromPackage(ClinicPackage package) {
    final fields = widget.formKey.currentState?.fields;
    if (_isPartial) {
      fields?['total_price']?.didChange(package.price.toString());
      fields?['amount']?.didChange('');
    } else {
      fields?['amount']?.didChange(package.price.toString());
    }
    fields?['session_added']?.didChange(
      package.kind.creditsSessionBalance
          ? package.sessionCount.toString()
          : '0',
    );
    fields?['traction_added']?.didChange(
      package.kind.creditsTractionBalance
          ? package.tractionsCount.toString()
          : '0',
    );
    setState(() {});
  }

  void _handlePartialChanged(bool isPartial) {
    final fields = widget.formKey.currentState?.fields;
    setState(() => _isPartial = isPartial);
    if (isPartial) {
      final String amount = fields?['amount']?.value as String? ?? '';
      fields?['total_price']?.didChange(
        _lastTotalPrice.isNotEmpty ? _lastTotalPrice : amount,
      );
    } else {
      _lastTotalPrice = fields?['total_price']?.value as String? ?? '';
      fields?['total_price']?.didChange(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPackage =
        _selectedReasonType == AppStrings.paymentReasonPackage;
    final bool isOther = _selectedReasonType == AppStrings.paymentReasonOther;
    final bool isAssessment = _isAssessment(_selectedReasonType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PaymentFormAmountSection(
          formKey: widget.formKey,
          enabled: widget.enabled,
          isPartial: _isPartial,
          onPartialChanged: _handlePartialChanged,
          onFieldChanged: () => setState(() {}),
        ),
        const SizedBox(height: AppSizes.p24),
        FormBuilderField<String>(
          name: 'reason_type',
          validator: FormBuilderValidators.required(
            errorText: AppStrings.reasonRequired,
          ),
          builder: (FormFieldState<String?> fieldState) {
            return PaymentReasonSection(
              options: paymentReasonPresets,
              selected: fieldState.value,
              enabled: widget.enabled,
              errorText: fieldState.errorText,
              onChanged: (String type) {
                fieldState.didChange(type);
                _handleReasonChanged(type);
              },
            );
          },
        ),
        if (isPackage) ...[
          const SizedBox(height: AppSizes.p24),
          PaymentFormPackageDropdown(
            enabled: widget.enabled,
            packages: widget.packages,
            onChanged: _seedAddersFromPackage,
          ),
        ],
        if (isOther) ...[
          const SizedBox(height: AppSizes.p24),
          FormBuilderTextField(
            name: 'custom_reason',
            enabled: widget.enabled,
            maxLines: 3,
            decoration: paymentInputDecoration(
              context,
              labelText: AppStrings.customReason,
              hintText: AppStrings.customReasonHint,
            ),
            validator: FormBuilderValidators.required(
              errorText: AppStrings.customReasonRequired,
            ),
          ),
        ],
        const SizedBox(height: AppSizes.p24),
        PaymentFormBalanceSection(
          enabled: widget.enabled,
          isAssessment: isAssessment,
          addToPackage: _addToPackage,
          onChanged: (bool value) => setState(() => _addToPackage = value),
          validateAddedInt: _validateAddedInt,
        ),
      ],
    );
  }

  String? _validateAddedInt(String? value) {
    if (value == null || value.isEmpty) return null;
    final int? parsed = int.tryParse(value);
    if (parsed == null || parsed < 0) {
      return AppStrings.amountMustBePositive;
    }
    return null;
  }
}
