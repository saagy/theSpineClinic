import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/widgets/auth_controllers.dart';
import 'package:spine_clinic_app/features/auth/presentation/widgets/auth_form_switcher.dart';
import 'package:spine_clinic_app/features/auth/presentation/widgets/auth_segmented_tab.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/shared/widgets/frosted_glass_card.dart';

/// Morphing frosted glass auth card housing the tab switcher and active form.
class FrostedAuthCard extends StatelessWidget {
  /// Creates a [FrostedAuthCard].
  const FrostedAuthCard({
    super.key,
    required this.mode,
    required this.isBusy,
    required this.ctrls,
    required this.selectedRole,
    required this.selectedBranch,
    required this.onTabChanged,
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
  final ValueChanged<bool> onTabChanged;
  final ValueChanged<UserRole> onRoleChanged;
  final ValueChanged<ClinicLocation?> onBranchChanged;
  final VoidCallback onLoginSubmit;
  final VoidCallback onNextToCredentials;
  final VoidCallback onBackToIdentity;
  final VoidCallback onRegisterSubmit;

  @override
  Widget build(BuildContext context) {
    final bool isRegister = mode != AuthMode.login;

    return FrostedGlassCard(
      padding: const EdgeInsets.all(AppSizes.p20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AuthSegmentedTab(
            isRegister: isRegister,
            enabled: !isBusy,
            onTabChanged: onTabChanged,
          ),
          const SizedBox(height: AppSizes.p16),
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              layoutBuilder: (current, prev) => Stack(
                alignment: Alignment.topCenter,
                children: [
                  ...prev,
                  if (current != null) current,
                ],
              ),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.03, 0),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: AuthFormSwitcher(
                mode: mode,
                isBusy: isBusy,
                ctrls: ctrls,
                selectedRole: selectedRole,
                selectedBranch: selectedBranch,
                onRoleChanged: onRoleChanged,
                onBranchChanged: onBranchChanged,
                onLoginSubmit: onLoginSubmit,
                onNextToCredentials: onNextToCredentials,
                onBackToIdentity: onBackToIdentity,
                onRegisterSubmit: onRegisterSubmit,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
