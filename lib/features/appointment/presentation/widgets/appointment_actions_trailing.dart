import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/shared/widgets/app_badge.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/all_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/my_schedule_controller.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_list_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';

/// Trailing actions for appointment rows.
///
/// - **Scheduled** (authorized staff): [Check In] pill + [✕] cancel icon (no badge).
/// - **Checked In**: green animated badge.
/// - **Cancelled / No Show**: red badge.
/// - **Completed**: green badge.
///
/// Check-in is immediate (no confirmation). Cancel always requires confirmation.
/// Rule 1 — keep files under 200 lines.
class AppointmentActionsTrailing extends ConsumerStatefulWidget {
  /// Creates an [AppointmentActionsTrailing].
  const AppointmentActionsTrailing({
    super.key,
    required this.appointment,
  });

  /// The appointment context.
  final Appointment appointment;

  @override
  ConsumerState<AppointmentActionsTrailing> createState() =>
      _AppointmentActionsTrailingState();
}

class _AppointmentActionsTrailingState
    extends ConsumerState<AppointmentActionsTrailing> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const SizedBox.shrink();

    final bool isAuthorizedStaff =
        user.role == UserRole.receptionist || user.role == UserRole.superAdmin;
    final AppointmentStatus status = widget.appointment.status;

    // ── Scheduled → action buttons for authorized staff, badge for others ──
    if (status == AppointmentStatus.scheduled) {
      if (isAuthorizedStaff) {
        return _buildScheduledActions();
      }
      return _badge(status);
    }

    // ── Checked In → green animated badge ──
    if (status == AppointmentStatus.checkedIn) {
      return _badge(status)
          .animate()
          .scale(duration: 300.ms, begin: const Offset(0.85, 0.85))
          .fadeIn(duration: 250.ms);
    }

    // ── Cancelled / No Show → red badge, Completed → green badge ──
    return _badge(status);
  }

  /// Action buttons for scheduled appointments: [Check In] pill + [✕] cancel.
  Widget _buildScheduledActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Check In pill button ──
        Material(
          color: _isProcessing ? AppColors.textMuted : AppColors.success,
          borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r24)),
          child: InkWell(
            borderRadius:
                const BorderRadius.all(Radius.circular(AppSizes.r24)),
            onTap: _isProcessing ? null : _handleCheckIn,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.p12,
                vertical: AppSizes.p6,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check, size: 16, color: AppColors.textOnPrimary),
                  const SizedBox(width: AppSizes.p4),
                  Text(
                    AppStrings.checkIn,
                    style: AppTextStyles.captionBold.copyWith(
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.p8),
        // ── Cancel icon button ──
        IconButton(
          tooltip: AppStrings.cancelAppointment,
          icon: const Icon(Icons.close),
          color: AppColors.danger,
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: _isProcessing ? null : _handleCancel,
        ),
      ],
    );
  }

  /// Status badge for terminal / non-actionable statuses.
  Widget _badge(AppointmentStatus status) {
    return AppBadge(
      label: status.displayLabel,
      textColor: status.textColor,
      backgroundColor: status.backgroundColor,
    );
  }

  /// Immediate check-in — no confirmation for speed (receptionist workflow).
  ///
  /// The [_isProcessing] flag prevents double-taps from firing
  /// two concurrent writes.
  Future<void> _handleCheckIn() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final result = await ref
          .read(appointmentRepositoryProvider)
          .updateAppointmentStatus(
              widget.appointment.id, AppointmentStatus.checkedIn);

      if (!mounted) return;

      result.when(
        success: (_) {
          _invalidateCaches();
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
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// Cancel with destructive confirmation dialog.
  Future<void> _handleCancel() async {
    if (_isProcessing) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmationDialog(
        title: AppStrings.cancelAppointment,
        message: AppStrings.confirmCancel,
        isDestructive: true,
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);
    try {
      final result = await ref
          .read(appointmentRepositoryProvider)
          .updateAppointmentStatus(
              widget.appointment.id, AppointmentStatus.cancelled);

      if (!mounted) return;

      result.when(
        success: (_) {
          _invalidateCaches();
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
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _invalidateCaches() {
    ref.invalidate(todayAppointmentsProvider);
    ref.read(allAppointmentsProvider.notifier).refresh();
    ref.invalidate(
        patientAppointmentsProvider(widget.appointment.patientId));
    ref.invalidate(patientDetailProvider(widget.appointment.patientId));
    ref.invalidate(myScheduleControllerProvider);
    ref.invalidate(patientListProvider);
  }
}
