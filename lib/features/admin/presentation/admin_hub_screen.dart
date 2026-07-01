/// Central dashboard hub for clinic administrators.
///
/// Replaces the legacy 2×2 management grid with a single vertical
/// column of menu rows beneath a profile header card, matching the
/// modern profile layout used by doctors and receptionists. The
/// reports row was removed because the same destination already lives
/// in the bottom nav.
///
/// Rule 1 — under 200 lines.
/// Rule 18/19 — the 2×2 grid chrome (`admin_hub_grid.dart`) is removed
///              because it conflicted with the new list-style layout.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/utils/theme_mode_controller.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_actions.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/auth/presentation/edit_profile_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/profile_menu_row.dart';
import 'package:spine_clinic_app/shared/widgets/staff_profile_header.dart';

/// Super-admin hub rendered as the "Admin" tab sub-page.
class AdminHubScreen extends ConsumerWidget {
  /// Creates an [AdminHubScreen].
  const AdminHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUser = ref.watch(currentUserProvider);

    return asyncUser.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: ErrorView(
          exception: error is AppException
              ? error
              : const UnknownException(message: AppStrings.errorDatabaseQueryFailed),
          onRetry: () => ref.invalidate(currentUserProvider),
        ),
      ),
      data: (user) {
        if (user == null || user.role != UserRole.superAdmin) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: ErrorView(
              exception: UnknownException(
                message: AppStrings.errorDatabasePermissionDenied,
                code: 'security/blocked',
              ),
            ),
          );
        }
        return _AdminHubBody(user: user);
      },
    );
  }
}

class _AdminHubBody extends ConsumerWidget {
  const _AdminHubBody({required this.user});
  final Staff user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode currentMode = ref.watch(themeModeControllerProvider);
    return SafeArea(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.profileLayoutMaxWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StaffProfileHeader(
                    user: user,
                    roleLabel: AppStrings.adminRoleLabel,
                    onEditProfile: () => EditProfileSheet.show(context, user),
                  ),
                  const SizedBox(height: AppSizes.p16),
                  ProfileMenuRow(
                    title: AppStrings.appointmentHistory,
                    subtitle: AppStrings.appointmentHistorySubtitle,
                    leadingIcon: Icons.history_rounded,
                    onTap: () => context.push(AppRoutes.doctorHistory),
                  ),
                  ProfileMenuRow(
                    title: AppStrings.staffManagement,
                    subtitle: AppStrings.manageStaffLabel,
                    leadingIcon: Icons.people_alt_rounded,
                    onTap: () => context.push(AppRoutes.staffList),
                  ),
                  ProfileMenuRow(
                    title: AppStrings.doctorApplications,
                    subtitle: AppStrings.manageDoctorsLabel,
                    leadingIcon: Icons.assignment_ind_rounded,
                    onTap: () => context.push(AppRoutes.doctorApplications),
                  ),
                  ProfileMenuRow(
                    title: AppStrings.clinicSettings,
                    subtitle: AppStrings.configureClinicLabel,
                    leadingIcon: Icons.settings_rounded,
                    onTap: () => context.push(AppRoutes.clinicSettings),
                  ),
                  ProfileMenuRow(
                    title: AppStrings.theme,
                    subtitle: AppStrings.themeSubtitle,
                    leadingIcon: Icons.palette_outlined,
                    trailing: Text(themeModeLabel(currentMode)),
                    onTap: () =>
                        ThemeModeController.pickFromSheet(context, ref),
                  ),
                  ProfileMenuRow(
                    title: AppStrings.signOut,
                    leadingIcon: Icons.logout_rounded,
                    isDestructive: true,
                    onTap: () => confirmAndSignOut(context, ref),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
