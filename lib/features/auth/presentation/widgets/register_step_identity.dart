import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_strings_auth.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/widgets/auth_role_selector.dart';
import 'package:spine_clinic_app/features/auth/presentation/widgets/auth_validators.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_dropdown.dart';
import 'package:spine_clinic_app/shared/widgets/app_text_input.dart';

/// Step 1 of registration: Identity details, staff role, and branch selection.
class RegisterStepIdentity extends StatelessWidget {
  /// Creates a [RegisterStepIdentity].
  const RegisterStepIdentity({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.selectedRole,
    required this.selectedBranch,
    required this.onRoleChanged,
    required this.onBranchChanged,
    required this.onNext,
    required this.isLoading,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final UserRole selectedRole;
  final ClinicLocation? selectedBranch;
  final ValueChanged<UserRole> onRoleChanged;
  final ValueChanged<ClinicLocation?> onBranchChanged;
  final VoidCallback onNext;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStringsAuth.stepIdentity,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.p4),
          Text(
            AppStringsAuth.stepIdentitySubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.p14),

          // Role Selector
          AuthRoleSelector(
            selectedRole: selectedRole,
            onRoleChanged: onRoleChanged,
            enabled: !isLoading,
          ),
          const SizedBox(height: AppSizes.p10),

          // Full Name
          AppTextInput(
            controller: nameController,
            labelText: AppStrings.fullName,
            prefixIcon: LucideIcons.user,
            validator: AuthValidators.fullName,
            enabled: !isLoading,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSizes.p10),

          // Email
          AppTextInput(
            controller: emailController,
            labelText: AppStrings.email,
            prefixIcon: LucideIcons.mail,
            keyboardType: TextInputType.emailAddress,
            validator: AuthValidators.email,
            enabled: !isLoading,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
          ),
          const SizedBox(height: AppSizes.p10),

          // Phone
          AppTextInput(
            controller: phoneController,
            labelText: AppStrings.phone,
            prefixIcon: LucideIcons.phone,
            keyboardType: TextInputType.phone,
            validator: AuthValidators.phone,
            enabled: !isLoading,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppSizes.p10),

          // Branch selector if Receptionist (Animated Expansion)
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            child: selectedRole == UserRole.receptionist
                ? Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.p10),
                    child: AppDropdown<ClinicLocation>(
                      value: selectedBranch,
                      labelText: AppStrings.branch,
                      hintText: AppStrings.selectBranch,
                      prefixIcon: LucideIcons.map_pin,
                      items: ClinicLocation.values
                          .map((loc) => DropdownMenuItem(
                                value: loc,
                                child: Text(loc.displayLabel),
                              ))
                          .toList(),
                      onChanged: isLoading ? null : onBranchChanged,
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: AppSizes.p4),

          // Next Step Button
          AppButton(
            labelText: AppStringsAuth.next,
            onPressed: isLoading ? null : onNext,
            shape: AppButtonShape.pill,
          ),
        ],
      ),
    );
  }
}

