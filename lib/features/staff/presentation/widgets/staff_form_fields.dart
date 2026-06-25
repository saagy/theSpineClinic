import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/shared/widgets/password_visibility_toggle.dart';

/// Isolated form fields for creating or editing staff members.
class StaffFormFields extends StatefulWidget {
  /// Creates a [StaffFormFields].
  const StaffFormFields({
    super.key,
    required this.enabled,
    required this.isSelf,
    this.staff,
    required this.formKey,
  });

  /// Whether the fields are interactive.
  final bool enabled;

  /// Whether the edited profile belongs to the currently logged-in user.
  final bool isSelf;

  /// The staff profile being edited (null for creation mode).
  final Staff? staff;

  /// The state key of the parent FormBuilder.
  final GlobalKey<FormBuilderState> formKey;

  @override
  State<StaffFormFields> createState() => _StaffFormFieldsState();
}

class _StaffFormFieldsState extends State<StaffFormFields> {
  bool _changePassword = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  InputDecoration _buildDecoration({required String labelText, String? hintText, Widget? suffixIcon}) {
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
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.staff != null;
    final showPasswordFields = !isEdit || _changePassword;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Full Name ──
        FormBuilderTextField(
          name: 'full_name',
          enabled: widget.enabled,
          initialValue: widget.staff?.fullName,
          textCapitalization: TextCapitalization.words,
          decoration: _buildDecoration(labelText: AppStrings.fullName, hintText: 'Enter full name'),
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(errorText: AppStrings.fullNameRequired),
            FormBuilderValidators.minLength(3, errorText: 'Min 3 characters required'),
          ]),
        ),
        const SizedBox(height: AppSizes.p16),

        // ── Email ──
        FormBuilderTextField(
          name: 'email',
          enabled: widget.enabled && !isEdit,
          initialValue: widget.staff?.email,
          keyboardType: TextInputType.emailAddress,
          decoration: _buildDecoration(labelText: AppStrings.email, hintText: 'Enter email address'),
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(errorText: AppStrings.emailRequired),
            FormBuilderValidators.email(errorText: AppStrings.emailInvalid),
          ]),
        ),
        const SizedBox(height: AppSizes.p16),

        // ── Phone ──
        FormBuilderTextField(
          name: 'phone',
          enabled: widget.enabled,
          initialValue: widget.staff?.phone,
          keyboardType: TextInputType.phone,
          decoration: _buildDecoration(labelText: AppStrings.phone, hintText: 'Enter phone number (optional)'),
        ),
        const SizedBox(height: AppSizes.p16),

        // ── Role Dropdown ──
        FormBuilderDropdown<UserRole>(
          name: 'role',
          enabled: widget.enabled && !widget.isSelf,
          initialValue: widget.staff?.role,
          decoration: _buildDecoration(labelText: AppStrings.role, hintText: 'Select staff role'),
          validator: FormBuilderValidators.required(errorText: AppStrings.roleRequired),
          items: const [
            DropdownMenuItem(
              value: UserRole.superAdmin,
              child: Text(AppStrings.superAdmin),
            ),
            DropdownMenuItem(
              value: UserRole.receptionist,
              child: Text(AppStrings.receptionist),
            ),
            DropdownMenuItem(
              value: UserRole.doctor,
              child: Text(AppStrings.doctor),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.p16),

        // ── Is Active Toggle ──
        if (isEdit) ...[
          FormBuilderSwitch(
            name: 'is_active',
            initialValue: widget.staff?.isActive ?? true,
            title: Text(
              AppStrings.isActive,
              style: AppTextStyles.body.copyWith(
                color: widget.enabled && !widget.isSelf ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
            enabled: widget.enabled && !widget.isSelf,
            decoration: const InputDecoration(border: InputBorder.none),
          ),
          const SizedBox(height: AppSizes.p8),
        ],

        // ── Change Password Toggle (Edit mode only) ──
        if (isEdit) ...[
          FormBuilderCheckbox(
            name: 'change_password',
            initialValue: false,
            title: Text(
              AppStrings.changePassword,
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
            ),
            enabled: widget.enabled,
            decoration: const InputDecoration(border: InputBorder.none),
            onChanged: (val) {
              setState(() {
                _changePassword = val ?? false;
              });
            },
          ),
          const SizedBox(height: AppSizes.p8),
        ],

        // ── Password fields ──
        if (showPasswordFields) ...[
          FormBuilderTextField(
            name: 'password',
            enabled: widget.enabled,
            obscureText: _obscurePassword,
            decoration: _buildDecoration(
              labelText: AppStrings.password,
              hintText: 'Enter password',
              suffixIcon: PasswordVisibilityToggle(
                isObscured: _obscurePassword,
                onToggle: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(errorText: AppStrings.passwordRequired),
              FormBuilderValidators.minLength(8, errorText: AppStrings.passwordMinLength),
            ]),
          ),
          const SizedBox(height: AppSizes.p16),
          FormBuilderTextField(
            name: 'confirm_password',
            enabled: widget.enabled,
            obscureText: _obscureConfirm,
            decoration: _buildDecoration(
              labelText: AppStrings.confirmPassword,
              hintText: 'Confirm password',
              suffixIcon: PasswordVisibilityToggle(
                isObscured: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) {
                return AppStrings.passwordRequired;
              }
              final password = widget.formKey.currentState?.fields['password']?.value as String?;
              if (val != password) {
                return AppStrings.passwordsDoNotMatch;
              }
              return null;
            },
          ),
        ],
      ],
    );
  }
}
