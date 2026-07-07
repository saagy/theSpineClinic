import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/admin/presentation/widgets/staff_application_review_card.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_applications_controller.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

/// Tab view displaying pending self-registered staff applications for approval.
class StaffApplicationsTab extends ConsumerWidget {
  /// Creates a [StaffApplicationsTab] instance.
  const StaffApplicationsTab({super.key});

  Future<void> _approve(
    BuildContext context,
    WidgetRef ref,
    Staff staff,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmationDialog(
        title: AppStrings.approveStaff,
        message: AppStrings.approveStaffMessage(staff.fullName),
        confirmLabel: AppStrings.approveApplication,
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(staffApplicationsActionProvider.notifier)
        .approveStaff(staff.id);
    if (!context.mounted) return;
    result.when(
      success: (_) => AppSnackbar.show(
        context,
        message: AppStrings.staffApprovedSuccess,
        variant: AppSnackbarVariant.success,
      ),
      failure: (error) => AppSnackbar.show(
        context,
        message: error.message,
        variant: AppSnackbarVariant.error,
      ),
    );
  }

  Future<void> _reject(BuildContext context, WidgetRef ref, Staff staff) async {
    final userId = staff.userId;
    if (userId == null) {
      AppSnackbar.show(
        context,
        message: AppStrings.staffMissingUserId,
        variant: AppSnackbarVariant.error,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmationDialog(
        title: AppStrings.rejectApplication,
        message: AppStrings.rejectStaffMessage(staff.fullName),
        confirmLabel: AppStrings.rejectAndDelete,
        isDestructive: true,
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(staffApplicationsActionProvider.notifier)
        .rejectStaff(staff.id, userId);
    if (!context.mounted) return;
    result.when(
      success: (_) => AppSnackbar.show(
        context,
        message: AppStrings.staffRejectedSuccess,
        variant: AppSnackbarVariant.success,
      ),
      failure: (error) => AppSnackbar.show(
        context,
        message: error.message,
        variant: AppSnackbarVariant.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingStaffApplicationsProvider);
    final actionState = ref.watch(staffApplicationsActionProvider);
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(pendingStaffApplicationsProvider.notifier).refresh(),
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: pendingAsync.when(
        data: (applications) => applications.isEmpty
            ? _empty()
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSizes.p16),
                itemCount: applications.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.p16),
                  child: StaffApplicationReviewCard(
                    staff: applications[index],
                    onApprove: () =>
                      _approve(context, ref, applications[index]),
                    onReject: () => _reject(context, ref, applications[index]),
                    isLoading: actionState.isLoading,
                  ),
                ),
              ),
        loading: () => Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        error: (error, _) => ErrorView(
          exception: error is AppException
              ? error
              : AppException.fromSupabaseException(error),
          onRetry: () =>
              ref.read(pendingStaffApplicationsProvider.notifier).refresh(),
        ),
      ),
    );
  }

  Widget _empty() => const SingleChildScrollView(
    physics: AlwaysScrollableScrollPhysics(),
    child: Center(
      child: Padding(
        padding: EdgeInsets.only(top: AppSizes.emptyStateTopOffset),
        child: EmptyState(
          message: AppStrings.noPendingApplications,
          icon: Icons.people_alt_rounded,
        ),
      ),
    ),
  );
}
