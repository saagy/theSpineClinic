import 'package:flutter/material.dart';
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
import 'package:spine_clinic_app/features/appointment/presentation/doctor_schedule_providers.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_list_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';

/// Trailing actions for appointment rows.
///
/// Always renders a status badge alongside a three-dot context menu (when the
/// user is authorized staff). Menu items adapt to the appointment's current
/// status:
///
/// - **Scheduled**: Check In (green) | Cancel (red, with confirmation)
/// - **Checked In**: Revert to Scheduled (gray) | Cancel (red, with confirmation)
/// - **Cancelled**: Restore Appointment (green)
/// - **Completed / No Show**: badge only, no menu
///
/// Rule 1 — keep files under 200 lines.
class AppointmentActionsTrailing extends ConsumerStatefulWidget {
  /// Creates an [AppointmentActionsTrailing].
  const AppointmentActionsTrailing({
    super.key,
    required this.appointment,
    this.onStatusChanged,
    this.showBadge = true,
  });

  /// The appointment context.
  final Appointment appointment;

  /// Called after a successful status change so the parent can refresh
  /// its local list without a full provider invalidation.
  final VoidCallback? onStatusChanged;

  /// Whether to render the status badge alongside the menu.
  /// Set to `false` when the parent card provides its own status indicator.
  final bool showBadge;

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
    final bool isAuthorizedStaff = user != null &&
        (user.role == UserRole.receptionist ||
         user.role == UserRole.superAdmin ||
         user.role == UserRole.doctor);
    final AppointmentStatus status = widget.appointment.status;
    final bool hasMenu = isAuthorizedStaff &&
        (status == AppointmentStatus.scheduled ||
         status == AppointmentStatus.checkedIn ||
         status == AppointmentStatus.cancelled);

    if (!hasMenu && !widget.showBadge) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showBadge) _badge(status),
        if (hasMenu) ...[
          if (widget.showBadge) const SizedBox(width: AppSizes.p4),
          _buildContextMenu(status),
        ],
      ],
    );
  }

  /// Three-dot context menu whose items adapt to [status].
  Widget _buildContextMenu(AppointmentStatus status) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_horiz_rounded,
        color: AppColors.textSecondary,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      splashRadius: AppSizes.iconDefault,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r12)),
      ),
      elevation: 1,
      position: PopupMenuPosition.under,
      enabled: !_isProcessing,
      onSelected: (String value) {
        switch (value) {
          case 'check_in':
            _handleCheckIn();
          case 'cancel':
            _handleCancel();
          case 'revert':
            _handleRevertToScheduled();
          case 'restore':
            _handleRestore();
        }
      },
      itemBuilder: (BuildContext context) => _buildMenuItems(status),
    );
  }

  List<PopupMenuItem<String>> _buildMenuItems(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return [
          _menuItem('check_in', Icons.check_circle_outline_rounded,
              AppColors.success, AppStrings.checkIn),
          _menuItem('cancel', Icons.close_rounded,
              AppColors.error, AppStrings.cancelAppointment),
        ];
      case AppointmentStatus.checkedIn:
        return [
          _menuItem('revert', Icons.undo_rounded,
              AppColors.textSecondary, 'Revert to Scheduled'),
          _menuItem('cancel', Icons.close_rounded,
              AppColors.error, AppStrings.cancelAppointment),
        ];
      case AppointmentStatus.cancelled:
        return [
          _menuItem('restore', Icons.refresh_rounded,
              AppColors.success, 'Restore Appointment'),
        ];
      default:
        return [];
    }
  }

  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    Color iconColor,
    String label,
  ) {
    return PopupMenuItem<String>(
      value: value,
      height: AppSizes.buttonHeightSmall,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: AppSizes.p8),
          Text(label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              )),
        ],
      ),
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

  /// Revert a checked-in appointment back to scheduled.
  Future<void> _handleRevertToScheduled() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final result = await ref
          .read(appointmentRepositoryProvider)
          .updateAppointmentStatus(widget.appointment.id, AppointmentStatus.scheduled);
      if (!mounted) return;
      result.when(
        success: (_) {
          widget.onStatusChanged?.call();
          AppSnackbar.show(context,
              message: AppStrings.statusUpdateSuccess,
              variant: AppSnackbarVariant.success);
        },
        failure: (error) {
          AppSnackbar.show(context,
              message: AppStrings.fromKey(error.userMessageKey),
              variant: AppSnackbarVariant.error);
        },
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// Restore a cancelled appointment back to scheduled.
  Future<void> _handleRestore() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final result = await ref
          .read(appointmentRepositoryProvider)
          .updateAppointmentStatus(widget.appointment.id, AppointmentStatus.scheduled);
      if (!mounted) return;
      result.when(
        success: (_) {
          widget.onStatusChanged?.call();
          AppSnackbar.show(context,
              message: AppStrings.statusUpdateSuccess,
              variant: AppSnackbarVariant.success);
        },
        failure: (error) {
          AppSnackbar.show(context,
              message: AppStrings.fromKey(error.userMessageKey),
              variant: AppSnackbarVariant.error);
        },
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _invalidateCaches() {
    ref.invalidate(todayAppointmentsProvider);
    ref.read(allAppointmentsProvider.notifier).refresh();
    ref.invalidate(patientAppointmentsProvider(widget.appointment.patientId));
    ref.invalidate(patientDetailProvider(widget.appointment.patientId));
    ref.invalidate(doctorScheduleProvider);
    ref.invalidate(patientListProvider);
    widget.onStatusChanged?.call();
  }
}
