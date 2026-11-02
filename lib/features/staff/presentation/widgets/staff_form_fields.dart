import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/shared/widgets/form_field_pair.dart';
import 'package:spine_clinic_app/shared/widgets/form_section.dart';
import 'staff_access_fields.dart';
import 'staff_account_fields.dart';
import 'staff_form_controls.dart';
import 'staff_password_fields.dart';

class StaffFormFields extends StatelessWidget {
  const StaffFormFields({
    super.key,
    required this.enabled,
    required this.isSelf,
    required this.formKey,
    this.staff,
    this.onSubmit,
  });
  final bool enabled;
  final bool isSelf;
  final GlobalKey<FormBuilderState> formKey;
  final Staff? staff;
  final VoidCallback? onSubmit;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
        child: Text(
          staff == null ? AppStrings.staffCreateHelp : AppStrings.staffEditHelp,
          style: AppTextStyles.bodySecondary.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      const SizedBox(height: AppSizes.p16),
      FormSection(
        title: AppStrings.personalDetails,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StaffTextField(
              name: 'full_name',
              label: AppStrings.fullName,
              enabled: enabled,
              initialValue: staff?.fullName,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(
                  errorText: AppStrings.fullNameRequired,
                ),
                FormBuilderValidators.minLength(
                  3,
                  errorText: AppStrings.fullNameMinLength,
                ),
              ]),
            ),
            const SizedBox(height: AppSizes.p20),
            FormFieldPair(
              first: StaffTextField(
                name: 'email',
                label: AppStrings.email,
                enabled: enabled,
                initialValue: staff?.email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(
                    errorText: AppStrings.emailRequired,
                  ),
                  FormBuilderValidators.email(
                    errorText: AppStrings.emailInvalid,
                  ),
                ]),
              ),
              second: StaffTextField(
                name: 'phone',
                label: AppStrings.profilePhoneLabel,
                enabled: enabled,
                initialValue: staff?.phone,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onSubmit?.call(),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSizes.p24),
      FormSection(
        title: AppStrings.clinicAccess,
        child: StaffAccessFields(
          enabled: enabled,
          isSelf: isSelf,
          staff: staff,
        ),
      ),
      const SizedBox(height: AppSizes.p24),
      FormSection(
        title: AppStrings.accountSecurity,
        child: staff == null
            ? StaffPasswordFields(
                enabled: enabled,
                formKey: formKey,
                onSubmit: onSubmit,
              )
            : StaffAccountFields(
                enabled: enabled,
                isSelf: isSelf,
                staff: staff!,
                formKey: formKey,
                onSubmit: onSubmit,
              ),
      ),
    ],
  );
}
