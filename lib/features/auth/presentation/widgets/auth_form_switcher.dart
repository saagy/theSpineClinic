import 'package:flutter/material.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/widgets/auth_controllers.dart';
import 'package:spine_clinic_app/features/auth/presentation/widgets/login_form.dart';
import 'package:spine_clinic_app/features/auth/presentation/widgets/register_step_credentials.dart';
import 'package:spine_clinic_app/features/auth/presentation/widgets/register_step_identity.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';

/// Active authentication form mode.
enum AuthMode { login, registerIdentity, registerCredentials }

/// Form switcher handling child form dispatch based on [AuthMode].
class AuthFormSwitcher extends StatelessWidget {
  /// Creates an [AuthFormSwitcher].
  const AuthFormSwitcher({
    super.key,
    required this.mode,
    required this.isBusy,
    required this.ctrls,
    required this.selectedRole,
    required this.selectedBranch,
    required this.onRoleChanged,
    required this.onBranchChanged,
    required this.onLoginSubmit,
    required this.onNextToCredentials,
    required this.onBackToIdentity,
    required this.onRegisterSubmit,
  });

  final AuthMode mode;
  final bool isBusy;
  final AuthControllers ctrls;
  final UserRole selectedRole;
  final ClinicLocation? selectedBranch;
  final ValueChanged<UserRole> onRoleChanged;
  final ValueChanged<ClinicLocation?> onBranchChanged;
  final VoidCallback onLoginSubmit;
  final VoidCallback onNextToCredentials;
  final VoidCallback onBackToIdentity;
  final VoidCallback onRegisterSubmit;

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case AuthMode.login:
        return LoginForm(
          key: const ValueKey('login'),
          formKey: ctrls.loginKey,
          emailController: ctrls.loginEmailCtrl,
          passwordController: ctrls.loginPasswordCtrl,
          isLoading: isBusy,
          onSubmit: onLoginSubmit,
        );
      case AuthMode.registerIdentity:
        return RegisterStepIdentity(
          key: const ValueKey('reg_id'),
          formKey: ctrls.regStep1Key,
          nameController: ctrls.regNameCtrl,
          emailController: ctrls.regEmailCtrl,
          phoneController: ctrls.regPhoneCtrl,
          selectedRole: selectedRole,
          selectedBranch: selectedBranch,
          onRoleChanged: onRoleChanged,
          onBranchChanged: onBranchChanged,
          onNext: onNextToCredentials,
          isLoading: isBusy,
        );
      case AuthMode.registerCredentials:
        return RegisterStepCredentials(
          key: const ValueKey('reg_cred'),
          formKey: ctrls.regStep2Key,
          passwordController: ctrls.regPasswordCtrl,
          confirmController: ctrls.regConfirmCtrl,
          onBack: onBackToIdentity,
          onSubmit: onRegisterSubmit,
          isLoading: isBusy,
        );
    }
  }
}
