import 'package:spine_clinic_app/shared/widgets/form_field_label.dart';
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
    required this.selectedClinic,
    required this.onClinicChanged,
    required this.enabled,
  });

  /// Controller for the patient's full name.
  final TextEditingController nameCtrl;

  /// Controller for the patient's phone number.
  final TextEditingController phoneCtrl;

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
          validator: (val) =>
              (val == null || val.trim().isEmpty) ? AppStrings.fullNameRequired : null,
        ),
        const SizedBox(height: AppSizes.p16),
        AppTextField(
          controller: phoneCtrl,
          labelText: AppStrings.phone,
          enabled: enabled,
          keyboardType: TextInputType.phone,
          validator: (val) =>
              (val == null || val.trim().isEmpty) ? AppStrings.phoneNumberRequired : null,
        ),
        const SizedBox(height: AppSizes.p16),
        _buildClinicDropdown(context),
      ],
    );
  }

  Widget _buildClinicDropdown(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.clinic,
          style: AppTextStyles.captionMedium.copyWith(
            color: enabled
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : ClinicColors.of(context).textMuted,
          ),
        ),
        const SizedBox(height: AppSizes.p6),
        DropdownButtonFormField<ClinicLocation>(
          initialValue: selectedClinic,
          style: AppTextStyles.body.copyWith(
            color: enabled
                ? Theme.of(context).colorScheme.onSurface
                : ClinicColors.of(context).textMuted,
          ),
          decoration: formInputDecoration(context),
          items: ClinicLocation.values
              .map((c) => DropdownMenuItem(value: c, child: Text(c.displayLabel)))
              .toList(),
          onChanged: enabled ? onClinicChanged : null,
          validator: (val) => val == null ? AppStrings.clinicRequired : null,
        ),
      ],
    );
  }
}
