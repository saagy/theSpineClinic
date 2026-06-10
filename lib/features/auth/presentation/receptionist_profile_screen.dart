/// Profile and settings screen for receptionist role.
///
/// Displays staff profile info, active branch selection dropdown,
/// and sign-out button. Branch selection is cached via LocalSettingsService.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/admin/presentation/branch_providers.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/info_row.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';

/// Profile/settings screen for receptionists with branch selection.
class ReceptionistProfileScreen extends ConsumerWidget {
  /// Creates a [ReceptionistProfileScreen].
  const ReceptionistProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUser = ref.watch(currentUserProvider);
    final activeBranch = ref.watch(activeBranchProvider);

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
                  // Profile info card
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
                        const InfoRow.fixedLabel(label: AppStrings.role, value: AppStrings.receptionistRoleLabel),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.p16),

                  // Branch selection
                  SectionCard(
                    title: AppStrings.activeBranch,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.branchSelectionHint,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSizes.p12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.p12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(AppSizes.r6),
                            ),
                            border: Border.all(
                              color: AppColors.border,
                              width: AppSizes.borderWidth,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<ClinicLocation>(
                              isExpanded: true,
                              value: activeBranch,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                              ),
                              items: ClinicLocation.values.map((loc) {
                                return DropdownMenuItem(
                                  value: loc,
                                  child: Text(loc.displayLabel),
                                );
                              }).toList(),
                              onChanged: (ClinicLocation? value) {
                                if (value != null) {
                                  ref
                                      .read(activeBranchProvider.notifier)
                                      .setBranch(value);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.p24),

                  // Sign out
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
