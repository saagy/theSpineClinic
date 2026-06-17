import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/edit_appointment_controller.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';

/// Button to delete an appointment with status guards and confirmation dialog.
class DeleteAppointmentButton extends ConsumerWidget {
  const DeleteAppointmentButton({super.key, required this.appointment});
  final Appointment appointment;

  Future<void> _onPressed(BuildContext context, WidgetRef ref) async {
    final status = appointment.status;
    if (status == AppointmentStatus.checkedIn || status == AppointmentStatus.completed) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cannot Delete'),
          content: const Text(AppStrings.cannotDeleteCheckedInOrCompleted),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(AppStrings.close),
            ),
          ],
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmationDialog(
        title: AppStrings.deleteAppointment,
        message: AppStrings.deleteAppointmentWarning,
        isDestructive: true,
      ),
    );

    if (confirm != true) return;

    final result = await ref.read(editAppointmentControllerProvider.notifier).deleteAppointment(
          appointmentId: appointment.id,
          patientId: appointment.patientId,
        );

    result.when(
      success: (_) {
        AppSnackbar.show(
          context,
          message: AppStrings.appointmentDeleted,
          variant: AppSnackbarVariant.success,
        );
        // Pop back to appointments list screen
        context.pop();
      },
      failure: (e) {
        AppSnackbar.show(
          context,
          message: AppStrings.fromKey(e.userMessageKey),
          variant: AppSnackbarVariant.error,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editState = ref.watch(editAppointmentControllerProvider);
    final isLoading = editState.isLoading;

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: const BorderSide(color: AppColors.error),
        padding: const EdgeInsets.symmetric(vertical: AppSizes.p14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.r12),
        ),
      ),
      onPressed: isLoading ? null : () => _onPressed(context, ref),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.error),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.delete_outline, size: 20),
                const SizedBox(width: AppSizes.p8),
                Text(
                  AppStrings.deleteAppointment,
                  style: AppTextStyles.bodyBold.copyWith(color: AppColors.error),
                ),
              ],
            ),
    );
  }
}
