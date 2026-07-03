import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/shared/widgets/app_text_field.dart';

/// Renders the demographics input form fields for editing a patient.
class PatientDemographicFields extends StatelessWidget {
  /// Creates a [PatientDemographicFields].
  const PatientDemographicFields({
    super.key,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.programCtrl,
    required this.selectedClinic,
    required this.onClinicChanged,
    required this.enabled,
  });

  /// Controller for the patient's full name.
  final TextEditingController nameCtrl;

  /// Controller for the patient's phone number.
  final TextEditingController phoneCtrl;

  /// Controller for the patient's program.
  final TextEditingController programCtrl;

  /// Currently selected clinic location.
  final ClinicLocation? selectedClinic;

  /// Callback when the clinic location changes.
  final ValueChanged<ClinicLocation?> onClinicChanged;

  /// Whether the fields are editable.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: nameCtrl,
          labelText: AppStrings.fullName,
          enabled: enabled,
          validator: (val) => (val == null || val.trim().isEmpty) ? 'Name is required' : null,
        ),
        const SizedBox(height: AppSizes.p16),
        AppTextField(
          controller: phoneCtrl,
          labelText: AppStrings.phone,
          enabled: enabled,
          keyboardType: TextInputType.phone,
          validator: (val) => (val == null || val.trim().isEmpty) ? 'Phone number is required' : null,
        ),
        const SizedBox(height: AppSizes.p16),
        AppTextField(
          controller: programCtrl,
          labelText: AppStrings.program,
          enabled: enabled,
        ),
        const SizedBox(height: AppSizes.p16),
        _buildClinicDropdown(context),
      ],
    );
  }

  Widget _buildClinicDropdown(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r6)),
      borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: AppSizes.borderWidth),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.clinic,
          style: AppTextStyles.captionMedium.copyWith(
            color: enabled ? Theme.of(context).colorScheme.onSurfaceVariant : ClinicColors.of(context).textMuted,
          ),
        ),
        const SizedBox(height: AppSizes.p6),
        DropdownButtonFormField<ClinicLocation>(
          initialValue: selectedClinic,
          style: AppTextStyles.body.copyWith(
            color: enabled ? Theme.of(context).colorScheme.onSurface : ClinicColors.of(context).textMuted,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: enabled ? Theme.of(context).colorScheme.surface : Theme.of(context).scaffoldBackgroundColor,
            contentPadding: AppSizes.paddingCell,
            enabledBorder: border,
            disabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: BorderSide(color: ClinicColors.of(context).outlineStrong, width: AppSizes.borderWidthFocused),
            ),
            errorBorder: border.copyWith(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: AppSizes.borderWidth),
            ),
            focusedErrorBorder: border.copyWith(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: AppSizes.borderWidthFocused),
            ),
          ),
          items: ClinicLocation.values
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c.displayLabel),
                  ))
              .toList(),
          onChanged: enabled ? onClinicChanged : null,
          validator: (val) => val == null ? 'Clinic is required' : null,
        ),
      ],
    );
  }
}
