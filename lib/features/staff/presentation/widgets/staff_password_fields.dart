import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/shared/widgets/app_input_decoration.dart';
import 'package:spine_clinic_app/shared/widgets/labeled_form_field.dart';
import 'package:spine_clinic_app/shared/widgets/password_visibility_toggle.dart';

class StaffPasswordFields extends StatefulWidget {
  const StaffPasswordFields({
    super.key,
    required this.enabled,
    required this.formKey,
    this.onSubmit,
    this.isNewAccount = true,
  });
  final bool enabled;
  final GlobalKey<FormBuilderState> formKey;
  final VoidCallback? onSubmit;
  final bool isNewAccount;
  @override
  State<StaffPasswordFields> createState() => _StaffPasswordFieldsState();
}

class _StaffPasswordFieldsState extends State<StaffPasswordFields> {
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      LabeledFormField(
        label: widget.isNewAccount
            ? AppStrings.password
            : AppStrings.newPasswordHint,
        enabled: widget.enabled,
        child: FormBuilderTextField(
          name: 'password',
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: (_) {
            final confirmation =
                widget.formKey.currentState?.fields['confirm_password'];
            if (confirmation != null &&
                (confirmation.isDirty || confirmation.hasError)) {
              confirmation.validate(focusOnInvalid: false);
            }
          },
          enabled: widget.enabled,
          obscureText: _obscurePassword,
          style: AppTextStyles.body,
          autocorrect: false,
          enableSuggestions: false,
          autofillHints: const [AutofillHints.newPassword],
          textInputAction: TextInputAction.next,
          decoration: appInputDecoration(
            context,
            enabled: widget.enabled,
            suffixIcon: PasswordVisibilityToggle(
              isObscured: _obscurePassword,
              onToggle: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(
              errorText: AppStrings.passwordRequired,
            ),
            FormBuilderValidators.minLength(
              8,
              errorText: AppStrings.passwordMinLength,
            ),
          ]),
        ),
      ),
      const SizedBox(height: AppSizes.p20),
      LabeledFormField(
        label: AppStrings.confirmPassword,
        enabled: widget.enabled,
        child: FormBuilderTextField(
          name: 'confirm_password',
          autovalidateMode: AutovalidateMode.onUserInteraction,
          enabled: widget.enabled,
          obscureText: _obscureConfirm,
          style: AppTextStyles.body,
          autocorrect: false,
          enableSuggestions: false,
          autofillHints: const [AutofillHints.newPassword],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => widget.onSubmit?.call(),
          decoration: appInputDecoration(
            context,
            enabled: widget.enabled,
            suffixIcon: PasswordVisibilityToggle(
              isObscured: _obscureConfirm,
              onToggle: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          validator: (String? value) {
            if (value == null || value.isEmpty) {
              return AppStrings.passwordRequired;
            }
            final String? password =
                widget.formKey.currentState?.fields['password']?.value
                    as String?;
            return value == password ? null : AppStrings.passwordsDoNotMatch;
          },
        ),
      ),
      const SizedBox(height: AppSizes.p8),
      Text(
        AppStrings.staffPasswordMinimum,
        style: AppTextStyles.caption.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}
