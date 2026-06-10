/// Doctor profile screen with historic appointments preview and logout.
///
/// Shows the doctor's own profile info, the last 5 appointments, a
/// "View All History" link, an "Edit Profile" button, and sign-out.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/auth/presentation/edit_profile_sheet.dart';
import 'package:spine_clinic_app/features/auth/presentation/widgets/recent_appointments_preview.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/info_row.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';

/// Doctor's own profile page with last-5 appointments preview and sign-out.
class DoctorProfileScreen extends ConsumerWidget {
  /// Creates a [DoctorProfileScreen].
  const DoctorProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUser = ref.watch(currentUserProvider);

    return asyncUser.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
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
        if (user == null) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: ErrorView(
              exception: UnknownException(message: AppStrings.errorAuthSessionExpired),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                        const InfoRow.fixedLabel(label: AppStrings.role, value: AppStrings.doctorRoleLabel),
                        const SizedBox(height: AppSizes.p16),
                        AppButton(
                          labelText: AppStrings.editProfile,
                          variant: AppButtonVariant.secondary,
                          onPressed: () => _showEditProfileSheet(context, ref, user),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.p16),
                  SectionCard(
                    title: AppStrings.recentAppointments,
                    action: TextButton(
                      onPressed: () => context.push(AppRoutes.doctorHistory),
                      child: Text(AppStrings.viewAll, style: AppTextStyles.bodyBold),
                    ),
                    child: RecentAppointmentsPreview(doctorId: user.id),
                  ),
                  const SizedBox(height: AppSizes.p24),
                  AppButton(
                    labelText: AppStrings.signOut,
                    variant: AppButtonVariant.danger,
                    onPressed: () => _handleSignOut(context, ref),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditProfileSheet(BuildContext context, WidgetRef ref, Staff user) {
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
