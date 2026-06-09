import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/shared/widgets/app_badge.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/my_schedule_controller.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';

/// Trailing actions grouped to fit into the `trailing` slot of [DataListTile].
/// Supports Check-In, Cancel, and View Details Pill actions.
/// Rule 1 — keep files under 200 lines.
class AppointmentActionsTrailing extends ConsumerWidget {
  /// Creates an [AppointmentActionsTrailing].
  const AppointmentActionsTrailing({
    super.key,
    required this.appointment,
  });

  /// The appointment context.
  final Appointment appointment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const SizedBox.shrink();

    final bool isAuthorizedStaff = user.role == UserRole.receptionist || user.role == UserRole.superAdmin;
    final bool showCheckIn = isAuthorizedStaff && appointment.status == AppointmentStatus.scheduled;
    final bool showCancel = isAuthorizedStaff && appointment.status == AppointmentStatus.scheduled;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBadge(
          label: appointment.status.displayLabel,
          textColor: appointment.status.textColor,
          backgroundColor: appointment.status.backgroundColor,
        ),
        const SizedBox(width: AppSizes.p12),
        if (showCheckIn) ...[
          IconButton(
            tooltip: AppStrings.checkIn,
            icon: const Icon(Icons.check_circle_outline),
            color: AppColors.success,
            iconSize: AppSizes.iconDefault,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _handleCheckIn(context, ref),
          ),
          const SizedBox(width: AppSizes.p12),
        ],
        if (showCancel) ...[
          IconButton(
            tooltip: AppStrings.cancelAppointment,
            icon: const Icon(Icons.cancel_outlined),
            color: AppColors.danger,
            iconSize: AppSizes.iconDefault,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _handleCancel(context, ref),
          ),
          const SizedBox(width: AppSizes.p12),
        ],
        GestureDetector(
          onTap: () => context.push(
            AppRoutes.appointmentDetail.replaceAll(':id', appointment.id),
          ),
          child: Container(
            decoration: const ShapeDecoration(
              color: AppColors.primaryLight,
              shape: StadiumBorder(),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.p12,
              vertical: AppSizes.p6,
            ),
            child: Text(
              AppStrings.viewDetails,
              style: AppTextStyles.captionBold.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleCheckIn(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmationDialog(
        title: AppStrings.checkInPatient,
        message: AppStrings.confirmCheckIn,
      ),
    );

    if (confirmed != true) return;

    final result = await ref
        .read(appointmentRepositoryProvider)
        .updateAppointmentStatus(appointment.id, AppointmentStatus.checkedIn);

    if (!context.mounted) return;

    result.when(
      success: (_) {
        _invalidateCaches(ref);
        AppSnackbar.show(
          context,
          message: AppStrings.statusUpdateSuccess,
          variant: AppSnackbarVariant.success,
        );
      },
      failure: (error) {
        AppSnackbar.show(
          context,
          message: AppStrings.fromKey(error.userMessageKey),
          variant: AppSnackbarVariant.error,
        );
      },
    );
  }

  Future<void> _handleCancel(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmationDialog(
        title: AppStrings.cancelAppointment,
        message: AppStrings.confirmCancel,
        isDestructive: true,
      ),
    );

    if (confirmed != true) return;

    final result = await ref
        .read(appointmentRepositoryProvider)
        .updateAppointmentStatus(appointment.id, AppointmentStatus.cancelled);

    if (!context.mounted) return;

    result.when(
      success: (_) {
        _invalidateCaches(ref);
        AppSnackbar.show(
          context,
          message: AppStrings.statusUpdateSuccess,
          variant: AppSnackbarVariant.success,
        );
      },
      failure: (error) {
        AppSnackbar.show(
          context,
          message: AppStrings.fromKey(error.userMessageKey),
          variant: AppSnackbarVariant.error,
        );
      },
    );
  }

  void _invalidateCaches(WidgetRef ref) {
    ref.invalidate(todayAppointmentsProvider);
    ref.invalidate(patientAppointmentsProvider(appointment.patientId));
    ref.invalidate(patientDetailProvider(appointment.patientId));
    ref.invalidate(myScheduleControllerProvider);
  }
}
