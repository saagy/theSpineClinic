import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';

/// Renders isolated form fields for NewPatientScreen.
class PatientFormFields extends StatelessWidget {
  /// Creates a [PatientFormFields].
  const PatientFormFields({super.key, required this.enabled});

  /// Whether the fields are interactive.
  final bool enabled;

  InputDecoration _buildDecoration(
    BuildContext context, {
    required String labelText,
    String? hintText,
  }) {
    final OutlineInputBorder borderBase = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r6)),
      borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: AppSizes.borderWidth),
    );

    return InputDecoration(
      labelText: labelText,
      labelStyle: AppTextStyles.captionMedium.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      isDense: true,
      filled: true,
      fillColor: enabled ? Theme.of(context).colorScheme.surface : Theme.of(context).scaffoldBackgroundColor,
      hintText: hintText,
      hintStyle: AppTextStyles.bodySecondary.copyWith(color: ClinicColors.of(context).textMuted),
      contentPadding: AppSizes.paddingCell,
      enabledBorder: borderBase,
      disabledBorder: borderBase,
      focusedBorder: borderBase.copyWith(
        borderSide: BorderSide(color: ClinicColors.of(context).outlineStrong, width: AppSizes.borderWidthFocused),
      ),
      errorBorder: borderBase.copyWith(
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: AppSizes.borderWidth),
      ),
      focusedErrorBorder: borderBase.copyWith(
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: AppSizes.borderWidthFocused),
      ),
      errorStyle: AppTextStyles.caption.copyWith(color: Theme.of(context).colorScheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Full Name ──
        FormBuilderTextField(
          name: 'full_name',
          enabled: enabled,
          textCapitalization: TextCapitalization.words,
          decoration: _buildDecoration(
            context,
            labelText: AppStrings.fullName,
            hintText: 'Enter full name',
          ),
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(errorText: 'Full name is required'),
            FormBuilderValidators.minLength(3, errorText: 'Min 3 characters required'),
          ]),
        ),
        const SizedBox(height: AppSizes.p16),

        // ── Phone Number ──
        FormBuilderTextField(
          name: 'phone_number',
          enabled: enabled,
          keyboardType: TextInputType.phone,
          decoration: _buildDecoration(
            context,
            labelText: AppStrings.phone,
            hintText: 'Enter phone number',
          ),
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(errorText: 'Phone number is required'),
            FormBuilderValidators.numeric(errorText: 'Must be numeric'),
          ]),
        ),
        const SizedBox(height: AppSizes.p16),


        // ── Program ──
        FormBuilderTextField(
          name: 'program',
          enabled: enabled,
          decoration: _buildDecoration(
            context,
            labelText: '${AppStrings.program} (optional)',
            hintText: 'Enter program details',
          ),
        ),
        const SizedBox(height: AppSizes.p16),

        // ── Clinic Selection ──
        FormBuilderDropdown<ClinicLocation>(
          name: 'clinic',
          enabled: enabled,
          decoration: _buildDecoration(
            context,
            labelText: AppStrings.clinic,
            hintText: 'Select clinic location',
          ),
          validator: FormBuilderValidators.required(errorText: 'Clinic location is required'),
          items: ClinicLocation.values
              .map((loc) => DropdownMenuItem(
                    value: loc,
                    child: Text(loc.displayLabel),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
