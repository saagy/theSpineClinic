import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/shared/widgets/app_input_decoration.dart';
import 'package:spine_clinic_app/shared/widgets/form_field_pair.dart';
import 'package:spine_clinic_app/shared/widgets/labeled_form_field.dart';
import 'staff_permission_field.dart';
import 'staff_seniority_field.dart';

class StaffAccessFields extends StatefulWidget {
  const StaffAccessFields({
    super.key,
    required this.enabled,
    required this.isSelf,
    this.staff,
  });
  final bool enabled;
  final bool isSelf;
  final Staff? staff;
  @override
  State<StaffAccessFields> createState() => _StaffAccessFieldsState();
}

class _StaffAccessFieldsState extends State<StaffAccessFields> {
  late UserRole? _role = widget.staff?.role;
  @override
  Widget build(BuildContext context) {
    final Widget role = LabeledFormField(
      label: AppStrings.role,
      enabled: widget.enabled && !widget.isSelf,
      child: FormBuilderDropdown<UserRole>(
        name: 'role',
        autovalidateMode: AutovalidateMode.onUserInteraction,
        isExpanded: true,
        borderRadius: BorderRadius.circular(AppSizes.r6),
        dropdownColor: Theme.of(context).colorScheme.surface,
        style: AppTextStyles.body.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        menuMaxHeight: AppSizes.overlayDropdownMaxHeight,
        enabled: widget.enabled && !widget.isSelf,
        initialValue: widget.staff?.role,
        decoration: appInputDecoration(
          context,
          enabled: widget.enabled && !widget.isSelf,
          hintText: AppStrings.roleHint,
        ),
        validator: FormBuilderValidators.required(
          errorText: AppStrings.roleRequired,
        ),
        onChanged: (UserRole? value) => setState(() => _role = value),
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
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormFieldPair(
          first: role,
          second: _role == UserRole.receptionist ? _branch(context) : null,
        ),
        if (widget.isSelf) ...[
          const SizedBox(height: AppSizes.p8),
          Text(
            AppStrings.staffOwnRoleHelp,
            style: AppTextStyles.caption.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (_role == UserRole.doctor) ...[
          const SizedBox(height: AppSizes.p12),
          StaffSeniorityField(
            enabled: widget.enabled,
            initialValue: widget.staff?.isSenior ?? false,
          ),
        ],
        if (_role == UserRole.receptionist) ...[
          const SizedBox(height: AppSizes.p12),
          StaffPermissionField(
            name: 'can_manage_payments',
            enabled: widget.enabled,
            initialValue: widget.staff?.canManagePayments ?? false,
            title: AppStrings.canManagePayments,
            description: AppStrings.staffPaymentsHelp,
          ),
        ],
      ],
    );
  }

  Widget _branch(BuildContext context) => LabeledFormField(
    label: AppStrings.branch,
    enabled: widget.enabled,
    child: FormBuilderDropdown<ClinicLocation>(
      name: 'branch',
      isExpanded: true,
      borderRadius: BorderRadius.circular(AppSizes.r6),
      dropdownColor: Theme.of(context).colorScheme.surface,
      style: AppTextStyles.body.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      menuMaxHeight: AppSizes.overlayDropdownMaxHeight,
      enabled: widget.enabled,
      initialValue: widget.staff?.branch,
      decoration: appInputDecoration(
        context,
        enabled: widget.enabled,
        hintText: AppStrings.selectBranch,
      ),
      items: ClinicLocation.values
          .map(
            (ClinicLocation branch) => DropdownMenuItem(
              value: branch,
              child: Text(branch.displayLabel),
            ),
          )
          .toList(),
    ),
  );
}
