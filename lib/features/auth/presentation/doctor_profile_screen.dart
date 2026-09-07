/// Doctor profile screen — unified identity header plus a stack of
/// settings menu rows (Appointment History, Sign Out).
///
/// The legacy "Recent Appointments" preview feed has been removed in
/// favor of a single tap-through row that opens the dedicated history
/// route.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/utils/theme_mode_controller.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_actions.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/auth/presentation/edit_profile_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/profile_menu_row.dart';
import 'package:spine_clinic_app/shared/widgets/staff_profile_header.dart';

/// Doctor's own profile page with history shortcut and sign-out.
class DoctorProfileScreen extends ConsumerWidget {
  /// Creates a [DoctorProfileScreen].
  const DoctorProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUser = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    return asyncUser.when(
      loading: () => Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: ErrorView(
          exception: error is AppException
              ? error
              : const UnknownException(
                  message: AppStrings.errorDatabaseQueryFailed,
                ),
          onRetry: () => ref.invalidate(currentUserProvider),
        ),
      ),
      data: (user) {
        if (user == null) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: const ErrorView(
              exception: UnknownException(
                message: AppStrings.errorAuthSessionExpired,
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StaffProfileHeader(
                    user: user,
                    roleLabel: _roleLabel(user.role),
                    onEditProfile: () => EditProfileSheet.show(context, user),
                  ),
                  const SizedBox(height: AppSizes.p16),
                  ProfileMenuRow(
                    title: AppStrings.appointmentHistory,
                    leadingIcon: Icons.history_rounded,
                    onTap: () => context.push(AppRoutes.doctorHistory),
                  ),
                  ProfileMenuRow(
                    title: AppStrings.theme,
                    subtitle: AppStrings.themeSubtitle,
                    leadingIcon: Icons.palette_outlined,
                    trailing: Text(
                      themeModeLabel(ref.watch(themeModeControllerProvider)),
                    ),
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
        );
      },
    );
  }
}

String _roleLabel(UserRole role) => switch (role) {
  UserRole.superAdmin => AppStrings.adminRoleLabel,
  UserRole.receptionist => AppStrings.receptionistRoleLabel,
  UserRole.doctor => AppStrings.doctorRoleLabel,
};
