/// Profile and settings screen for the receptionist role.
///
/// Displays the staff identity header, the active branch selector
/// inlined as a settings row, and a destructive sign-out row.
///
/// The legacy standalone "Active Branch" card and full-width logout
/// button have been replaced with compact menu rows that match the
/// modern profile layout shared with the doctor role.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/utils/theme_mode_controller.dart';
import 'package:spine_clinic_app/features/admin/presentation/branch_providers.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_actions.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/auth/presentation/edit_profile_sheet.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/profile_menu_row.dart';
import 'package:spine_clinic_app/shared/widgets/staff_profile_header.dart';

/// Profile/settings screen for receptionists.
class ReceptionistProfileScreen extends ConsumerWidget {
  /// Creates a [ReceptionistProfileScreen].
  const ReceptionistProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUser = ref.watch(currentUserProvider);
    final activeBranch = ref.watch(activeBranchProvider);
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
                    roleLabel: AppStrings.receptionistRoleLabel,
                    onEditProfile: () => EditProfileSheet.show(context, user),
                  ),
                  const SizedBox(height: AppSizes.p16),
                  ProfileMenuRow(
                    title: AppStrings.activeBranch,
                    leadingIcon: Icons.business_rounded,
                    onTap: null,
                    trailing: _BranchDropdown(
                      value: activeBranch,
                      onChanged: (loc) => ref
                          .read(activeBranchProvider.notifier)
                          .setBranch(loc),
                    ),
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

/// Compact inline branch picker rendered as the trailing slot of the
/// Active Branch menu row. Drops the legacy [Container]-wrapped chrome
/// in favor of plain dropdown chrome inside the menu tile.
class _BranchDropdown extends StatelessWidget {
  /// Creates an [_BranchDropdown].
  const _BranchDropdown({required this.value, required this.onChanged});

  /// The currently selected branch.
  final ClinicLocation value;

  /// Callback invoked when the user picks a different branch.
  final ValueChanged<ClinicLocation> onChanged;

  @override
  Widget build(BuildContext context) {
    final Color textColor = Theme.of(context).colorScheme.onSurface;

    return DropdownButtonHideUnderline(
      child: DropdownButton<ClinicLocation>(
        isDense: true,
        value: value,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r8)),
        style: AppTextStyles.bodyMedium.copyWith(color: textColor),
        items: ClinicLocation.values
            .map(
              (loc) =>
                  DropdownMenuItem(value: loc, child: Text(loc.displayLabel)),
            )
            .toList(),
        onChanged: (ClinicLocation? next) {
          if (next != null) onChanged(next);
        },
      ),
    );
  }
}
