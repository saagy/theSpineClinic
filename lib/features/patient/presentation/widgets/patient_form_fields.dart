import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/shared/widgets/form_field_label.dart';

class PatientFormFields extends StatelessWidget {
  const PatientFormFields({super.key, required this.enabled});
  final bool enabled;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FormFieldLabel(
        label: AppStrings.fullName,
        child: FormBuilderTextField(
          name: 'full_name',
          enabled: enabled,
          style: AppTextStyles.body,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: formInputDecoration(context, hint: AppStrings.fullNameHint),
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(errorText: AppStrings.fullNameRequired),
            FormBuilderValidators.minLength(3, errorText: AppStrings.fullNameMinLength),
          ]),
        ),
      ),
      const SizedBox(height: AppSizes.p20),
      FormFieldLabel(
        label: AppStrings.phone,
        child: FormBuilderTextField(
          name: 'phone_number',
          enabled: enabled,
          style: AppTextStyles.body,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          decoration: formInputDecoration(context, hint: AppStrings.phoneNumberHint),
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(errorText: AppStrings.phoneNumberRequired),
            FormBuilderValidators.numeric(errorText: AppStrings.phoneNumeric),
          ]),
        ),
      ),
      const SizedBox(height: AppSizes.p20),
      FormFieldLabel(
        label: AppStrings.clinic,
        child: FormBuilderDropdown<ClinicLocation>(
          name: 'clinic',
          enabled: enabled,
          style: AppTextStyles.body.copyWith(color: Theme.of(context).colorScheme.onSurface),
          decoration: formInputDecoration(context, hint: AppStrings.selectClinicLocation),
          validator: FormBuilderValidators.required(errorText: AppStrings.clinicRequired),
          items: [
            for (final clinic in ClinicLocation.values)
              DropdownMenuItem(value: clinic, child: Text(clinic.displayLabel)),
          ],
        ),
      ),
    ],
  );
}
