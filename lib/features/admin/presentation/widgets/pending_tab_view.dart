import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/admin/presentation/doctor_applications_controller.dart';
import 'package:spine_clinic_app/features/admin/presentation/widgets/application_action_buttons.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/data_list_tile.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';

/// Tab body rendering the list of inactive/pending doctor registration applications.
class PendingTabView extends ConsumerWidget {
  /// Creates a [PendingTabView] instance.
  const PendingTabView({super.key});

  Future<void> _approve(BuildContext context, WidgetRef ref, Staff doctor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Approve Doctor',
        message: 'Approve Dr. ${doctor.fullName}? They will be able to log in immediately.',
        confirmLabel: 'Approve',
      ),
    );

    if (confirmed == true && context.mounted) {
      final result = await ref
          .read(doctorApplicationsActionProvider.notifier)
          .approveDoctor(doctor.id);

      if (context.mounted) {
        result.when(
          success: (_) => AppSnackbar.show(
            context,
            message: 'Doctor approved successfully.',
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

  Future<void> _reject(BuildContext context, WidgetRef ref, Staff doctor) async {
    if (doctor.userId == null) {
      AppSnackbar.show(
        context,
        message: 'Cannot reject application: Doctor has no associated User ID.',
        variant: AppSnackbarVariant.error,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Reject Application',
        message: 'Reject and delete Dr. ${doctor.fullName}\'s application? This will permanently delete their account and profile. This action cannot be undone.',
        confirmLabel: 'Reject & Delete',
        isDestructive: true,
      ),
    );

    if (confirmed == true && context.mounted) {
      final result = await ref
          .read(doctorApplicationsActionProvider.notifier)
          .rejectDoctor(doctor.id, doctor.userId!);

      if (context.mounted) {
        result.when(
          success: (_) => AppSnackbar.show(
            context,
            message: 'Application rejected and deleted.',
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
    final pendingAsync = ref.watch(pendingDoctorApplicationsProvider);
    final actionState = ref.watch(doctorApplicationsActionProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(pendingDoctorApplicationsProvider.notifier).refresh(),
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: pendingAsync.when(
        data: (applications) {
          if (applications.isEmpty) {
            return const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 100),
                  child: EmptyState(
                    message: AppStrings.noPendingApplications,
                    icon: Icons.people_alt_rounded,
                  ),
                ),
              ),
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSizes.p16),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final doctor = applications[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.p16),
                child: SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DataListTile(
                        title: doctor.fullName,
                        subtitle: '${doctor.email} • ${doctor.phone != null ? Formatters.formatPhone(doctor.phone!) : 'No phone'} • Reg: ${doctor.createdAt.toShortDateString()}',
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            doctor.fullName.isNotEmpty ? doctor.fullName[0].toUpperCase() : '?',
                            style: AppTextStyles.bodyBold.copyWith(color: AppColors.primary),
                          ),
                        ),
                        transparent: true,
                      ),
                      const SizedBox(height: AppSizes.p12),
                      ApplicationActionButtons(
                        onApprove: () => _approve(context, ref, doctor),
                        onReject: () => _reject(context, ref, doctor),
                        isLoading: actionState.isLoading,
                      ),
                    ],
                  ),
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
          onRetry: () => ref.read(pendingDoctorApplicationsProvider.notifier).refresh(),
        ),
      ),
    );
  }
}
