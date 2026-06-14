import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/admin/presentation/widgets/admin_hub_grid.dart';
import 'package:spine_clinic_app/features/auth/presentation/edit_profile_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/info_row.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';

/// Central dashboard hub for clinic administrators.
/// Enforces Super Admin role-based protection on mount.
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

  static const _destinations = [
    HubDestination(
      title: AppStrings.staffManagement,
      subtitle: AppStrings.manageStaffLabel,
      icon: Icons.people_alt_rounded,
      route: AppRoutes.staffList,
    ),
    HubDestination(
      title: AppStrings.doctorApplications,
      subtitle: AppStrings.manageDoctorsLabel,
      icon: Icons.assignment_ind_rounded,
      route: AppRoutes.doctorApplications,
    ),
    HubDestination(
      title: AppStrings.clinicSettings,
      subtitle: AppStrings.configureClinicLabel,
      icon: Icons.settings_rounded,
      route: AppRoutes.clinicSettings,
    ),
    HubDestination(
      title: AppStrings.reportsAndAnalytics,
      subtitle: AppStrings.viewReportsLabel,
      icon: Icons.analytics_rounded,
      route: AppRoutes.reports,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSizes.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AdminHubGrid(destinations: _destinations),
          const SizedBox(height: AppSizes.p24),
          SectionCard(
            title: AppStrings.profile,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoRow.fixedLabel(label: AppStrings.fullName, value: user.fullName),
                const SizedBox(height: AppSizes.p12),
                InfoRow.fixedLabel(label: AppStrings.email, value: user.email),
                if (user.phone != null && user.phone!.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.p12),
                  InfoRow.fixedLabel(label: AppStrings.phone, value: user.phone!),
                ],
                const SizedBox(height: AppSizes.p12),
                const InfoRow.fixedLabel(label: AppStrings.role, value: AppStrings.adminRoleLabel),
                const SizedBox(height: AppSizes.p16),
                AppButton(
                  labelText: AppStrings.editProfile,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => _showEditProfileSheet(context, user),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.p24),
          AppButton(
            labelText: AppStrings.signOut,
            variant: AppButtonVariant.danger,
            onPressed: () => _handleSignOut(context, ref),
          ),
        ],
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context, Staff user) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.r12)),
      ),
      builder: (_) => EditProfileSheet(staff: user),
    );
  }

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => const ConfirmationDialog(
        title: AppStrings.signOut,
        message: AppStrings.confirmSignOut,
        confirmLabel: AppStrings.signOut,
        cancelLabel: AppStrings.cancel,
        isDestructive: true,
      ),
    );
    if (confirm == true) {
      await ref.read(currentUserProvider.notifier).logout();
    }
  }
}
