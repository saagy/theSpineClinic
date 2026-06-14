/// Role-guarded action buttons for the appointment detail screen.
///
/// SCHEDULED → full-width teal "Check In" + borderless red "Cancel".
/// CHECKED_IN → outlined "Revert to Scheduled" + borderless "Cancel".
/// CANCELLED → outlined "Restore Appointment".
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_detail_controller.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_status_actions.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';

/// Displays role- and status-guarded action buttons in a low-profile sticky bar.
class AppointmentActionButtons extends ConsumerStatefulWidget {
  const AppointmentActionButtons({
    super.key,
    required this.appointment,
    required this.userRole,
  });
  final Appointment appointment;
  final UserRole userRole;

  @override
  ConsumerState<AppointmentActionButtons> createState() =>
      _AppointmentActionButtonsState();
}

class _AppointmentActionButtonsState
    extends ConsumerState<AppointmentActionButtons> {
  bool _loading = false;

  bool get _isScheduled =>
      widget.appointment.status == AppointmentStatus.scheduled;
  bool get _isCheckedIn =>
      widget.appointment.status == AppointmentStatus.checkedIn;
  bool get _isCancelled =>
      widget.appointment.status == AppointmentStatus.cancelled;

  // ── Status-conditional build ─────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isScheduled) {
      return ScheduledActions(
        loading: _loading,
        onCheckIn: () => _act(_checkIn),
        onCancel: () => _act(_cancel),
      );
    }
    if (_isCheckedIn) {
      return CheckedInActions(
        loading: _loading,
        onRevert: () => _act(_revert),
        onCancel: () => _act(_cancel),
      );
    }
    if (_isCancelled) {
      return CancelledActions(
        loading: _loading,
        onRestore: () => _act(_restore),
      );
    }
    return const SizedBox.shrink();
  }

  // ── Action dispatcher ───────────────────────────────────────────────────

  Future<void> _act(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
    } on Exception catch (_) {
      if (mounted) {
        AppSnackbar.show(context,
            message: AppStrings.statusUpdateError,
            variant: AppSnackbarVariant.error);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _checkIn() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmationDialog(
          title: AppStrings.checkInPatient,
          message: AppStrings.confirmCheckIn),
    );
    if (ok != true) { return; }
    await ref
        .read(appointmentDetailControllerProvider(widget.appointment.id)
            .notifier)
        .checkIn();
    if (mounted) {
      AppSnackbar.show(context,
          message: AppStrings.statusUpdateSuccess,
          variant: AppSnackbarVariant.success);
    }
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmationDialog(
          title: AppStrings.cancelAppointment,
          message: AppStrings.confirmCancel,
          isDestructive: true),
    );
    if (ok != true) { return; }
    await ref
        .read(appointmentDetailControllerProvider(widget.appointment.id)
            .notifier)
        .cancel();
    if (mounted) {
      AppSnackbar.show(context,
          message: AppStrings.statusUpdateSuccess,
          variant: AppSnackbarVariant.success);
    }
  }

  Future<void> _revert() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmationDialog(
          title: AppStrings.revertToScheduled,
          message: AppStrings.confirmRevert),
    );
    if (ok != true) { return; }
    await ref
        .read(appointmentDetailControllerProvider(widget.appointment.id)
            .notifier)
        .revertToScheduled();
    if (mounted) {
      AppSnackbar.show(context,
          message: AppStrings.statusUpdateSuccess,
          variant: AppSnackbarVariant.success);
    }
  }

  Future<void> _restore() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmationDialog(
          title: AppStrings.restoreToScheduled,
          message: AppStrings.confirmRestore),
    );
    if (ok != true) { return; }
    await ref
        .read(appointmentDetailControllerProvider(widget.appointment.id)
            .notifier)
        .revertToScheduled();
    if (mounted) {
      AppSnackbar.show(context,
          message: AppStrings.statusUpdateSuccess,
          variant: AppSnackbarVariant.success);
    }
  }
}
