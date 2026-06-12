import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/admin/presentation/clinic_settings_controller.dart';
import 'package:spine_clinic_app/features/admin/presentation/widgets/clinic_package_card.dart';
import 'package:spine_clinic_app/features/admin/presentation/widgets/package_form_sheet.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/payments/domain/clinic_package.dart';
import 'package:spine_clinic_app/features/payments/presentation/record_payment_controller.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

/// Screen configured to manage global clinic packages and pricing.
/// Protected by a Super Admin role guard.
class ClinicSettingsScreen extends ConsumerWidget {
  /// Creates a [ClinicSettingsScreen] instance.
  const ClinicSettingsScreen({super.key});

  void _addPackage(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.r12)),
      ),
      builder: (context) => PackageFormSheet(
        onSave: (package) async {
          Navigator.of(context).pop();
          final result = await ref
              .read(clinicSettingsActionProvider.notifier)
              .addPackage(package);

          if (context.mounted) {
            result.when(
              success: (_) => AppSnackbar.show(
                context,
                message: AppStrings.packageCreatedSuccess,
                variant: AppSnackbarVariant.success,
              ),
              failure: (error) => AppSnackbar.show(
                context,
                message: error.message,
                variant: AppSnackbarVariant.error,
              ),
            );
          }
        },
      ),
    );
  }

  void _editPackage(BuildContext context, WidgetRef ref, int index, ClinicPackage package) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.r12)),
      ),
      builder: (context) => PackageFormSheet(
        package: package,
        onSave: (updatedPackage) async {
          Navigator.of(context).pop();
          final result = await ref
              .read(clinicSettingsActionProvider.notifier)
              .editPackage(index, updatedPackage);

          if (context.mounted) {
            result.when(
              success: (_) => AppSnackbar.show(
                context,
                message: AppStrings.packageUpdatedSuccess,
                variant: AppSnackbarVariant.success,
              ),
              failure: (error) => AppSnackbar.show(
                context,
                message: error.message,
                variant: AppSnackbarVariant.error,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _deletePackage(BuildContext context, WidgetRef ref, int index, ClinicPackage package) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmationDialog(
        title: AppStrings.delete,
        message: AppStrings.deletePackageConfirm,
        confirmLabel: AppStrings.delete,
        isDestructive: true,
      ),
    );

    if (confirmed == true && context.mounted) {
      final result = await ref
          .read(clinicSettingsActionProvider.notifier)
          .deletePackage(index);

      if (context.mounted) {
        result.when(
          success: (_) => AppSnackbar.show(
            context,
            message: AppStrings.packageDeletedSuccess,
            variant: AppSnackbarVariant.success,
          ),
          failure: (error) => AppSnackbar.show(
            context,
            message: error.message,
            variant: AppSnackbarVariant.error,
          ),
        );
      }
    }
  }

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

        final packagesAsync = ref.watch(clinicPackagesProvider);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            title: const Text(AppStrings.clinicSettings),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () => ref.refresh(clinicPackagesProvider.future),
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            child: packagesAsync.when(
              data: (packages) {
                if (packages.isEmpty) {
                  return const SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: AppSizes.emptyStateTopOffset),
                        child: EmptyState(
                          message: AppStrings.noPackages,
                          icon: Icons.inventory_2_outlined,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSizes.p16),
                  itemCount: packages.length,
                  itemBuilder: (context, index) {
                    final package = packages[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.p12),
                      child: ClinicPackageCard(
                        package: package,
                        onEdit: () => _editPackage(context, ref, index, package),
                        onDelete: () => _deletePackage(context, ref, index, package),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (error, _) => ErrorView(
                exception: error is AppException ? error : AppException.fromSupabaseException(error),
                onRetry: () => ref.refresh(clinicPackagesProvider.future),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _addPackage(context, ref),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            icon: const Icon(Icons.add_rounded),
            label: const Text(AppStrings.addPackage),
          ),
        );
      },
    );
  }
}
