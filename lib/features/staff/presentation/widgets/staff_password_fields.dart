import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_form_controls.dart';
import 'package:spine_clinic_app/shared/widgets/password_visibility_toggle.dart';

class StaffPasswordFields extends StatefulWidget {
  const StaffPasswordFields({
    super.key,
    required this.enabled,
    required this.formKey,
  });

  final bool enabled;
  final GlobalKey<FormBuilderState> formKey;

  @override
  State<StaffPasswordFields> createState() => _StaffPasswordFieldsState();
}

class _StaffPasswordFieldsState extends State<StaffPasswordFields> {
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FormBuilderTextField(
          name: 'password',
          enabled: widget.enabled,
          obscureText: _obscurePassword,
          decoration: staffInputDecoration(
            context,
            AppStrings.password,
            enabled: widget.enabled,
            hint: AppStrings.passwordHint,
            suffix: PasswordVisibilityToggle(
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
        const SizedBox(height: AppSizes.p16),
        FormBuilderTextField(
          name: 'confirm_password',
          enabled: widget.enabled,
          obscureText: _obscureConfirm,
          decoration: staffInputDecoration(
            context,
            AppStrings.confirmPassword,
            enabled: widget.enabled,
            hint: AppStrings.confirmPasswordHint,
            suffix: PasswordVisibilityToggle(
              isObscured: _obscureConfirm,
              onToggle: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          validator: _confirmPassword,
        ),
      ],
    );
  }

  String? _confirmPassword(String? value) {
    if (value == null || value.isEmpty) return AppStrings.passwordRequired;
    final password =
        widget.formKey.currentState?.fields['password']?.value as String?;
    return value == password ? null : AppStrings.passwordsDoNotMatch;
  }
}
