import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_form_controls.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_password_fields.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';

class StaffFormFields extends StatefulWidget {
  const StaffFormFields({
    super.key,
    required this.enabled,
    required this.isSelf,
    required this.formKey,
    this.staff,
  });

  final bool enabled;
  final bool isSelf;
  final GlobalKey<FormBuilderState> formKey;
  final Staff? staff;

  @override
  State<StaffFormFields> createState() => _StaffFormFieldsState();
}

class _StaffFormFieldsState extends State<StaffFormFields> {
  bool _changePassword = false;
  UserRole? _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.staff?.role;
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.staff != null;
    final bool showPasswords = !isEdit || _changePassword;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _section(AppStrings.identity, _identityFields),
        const SizedBox(height: AppSizes.p16),
        _section(AppStrings.access, _accessFields),
        const SizedBox(height: AppSizes.p16),
        _section(AppStrings.account, [
          if (isEdit) ..._accountFields,
          if (showPasswords) ...[
            if (isEdit) const SizedBox(height: AppSizes.p8),
            StaffPasswordFields(
              enabled: widget.enabled,
              formKey: widget.formKey,
            ),
          ],
        ]),
      ],
    );
  }

  List<Widget> get _identityFields => [
    StaffTextField(
      name: 'full_name',
      label: AppStrings.fullName,
      hint: AppStrings.fullNameHint,
      enabled: widget.enabled,
      initialValue: widget.staff?.fullName,
      textCapitalization: TextCapitalization.words,
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: AppStrings.fullNameRequired),
        FormBuilderValidators.minLength(
          3,
          errorText: AppStrings.fullNameMinLength,
        ),
      ]),
    ),
    const SizedBox(height: AppSizes.p16),
    StaffTextField(
      name: 'email',
      label: AppStrings.email,
      hint: AppStrings.emailHint,
      enabled: widget.enabled,
      initialValue: widget.staff?.email,
      keyboardType: TextInputType.emailAddress,
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: AppStrings.emailRequired),
        FormBuilderValidators.email(errorText: AppStrings.emailInvalid),
      ]),
    ),
    const SizedBox(height: AppSizes.p16),
    StaffTextField(
      name: 'phone',
      label: AppStrings.phone,
      hint: AppStrings.phoneOptionalHint,
      enabled: widget.enabled,
      initialValue: widget.staff?.phone,
      keyboardType: TextInputType.phone,
    ),
  ];

  List<Widget> get _accessFields => [
    FormBuilderDropdown<UserRole>(
      name: 'role',
      enabled: widget.enabled && !widget.isSelf,
      initialValue: widget.staff?.role,
      decoration: staffInputDecoration(
        context,
        AppStrings.role,
        enabled: widget.enabled,
        hint: AppStrings.roleHint,
      ),
      validator: FormBuilderValidators.required(
        errorText: AppStrings.roleRequired,
      ),
      onChanged: (role) => setState(() => _selectedRole = role),
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
    if (_selectedRole == UserRole.receptionist) ...[
      const SizedBox(height: AppSizes.p16),
      FormBuilderDropdown<ClinicLocation>(
        name: 'branch',
        enabled: widget.enabled,
        initialValue: widget.staff?.branch,
        decoration: staffInputDecoration(
          context,
          AppStrings.branch,
          enabled: widget.enabled,
          hint: AppStrings.selectBranch,
        ),
        items: ClinicLocation.values
            .map(
              (branch) => DropdownMenuItem(
                value: branch,
                child: Text(branch.displayLabel),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: AppSizes.p8),
      FormBuilderSwitch(
        name: 'can_manage_payments',
        initialValue: widget.staff?.canManagePayments ?? false,
        title: Text(AppStrings.canManagePayments, style: AppTextStyles.body),
        enabled: widget.enabled,
        decoration: const InputDecoration(border: InputBorder.none),
      ),
    ],
  ];

  List<Widget> get _accountFields => [
    FormBuilderSwitch(
      name: 'is_active',
      initialValue: widget.staff?.isActive ?? true,
      title: Text(AppStrings.accountEnabled, style: AppTextStyles.body),
      enabled: widget.enabled && !widget.isSelf,
      decoration: const InputDecoration(border: InputBorder.none),
    ),
    const SizedBox(height: AppSizes.p8),
    FormBuilderCheckbox(
      name: 'change_password',
      initialValue: false,
      title: Text(AppStrings.changePassword, style: AppTextStyles.body),
      enabled: widget.enabled,
      decoration: const InputDecoration(border: InputBorder.none),
      onChanged: (value) => setState(() => _changePassword = value ?? false),
    ),
  ];

  Widget _section(String title, List<Widget> children) {
    return SectionCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
