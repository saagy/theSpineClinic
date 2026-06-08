/// Role-guarded action buttons for the appointment detail screen.
///
/// Conditionally renders Check In, Cancel, and Mark Complete buttons
/// based on the current user's role and the appointment's status.
///
/// AGENT_CONTEXT §4 — Permission Access Matrix enforcement.
/// Rule 1 — extracted sub-widget to keep files under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_detail_controller.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';

/// Displays role- and status-guarded action buttons.
class AppointmentActionButtons extends ConsumerStatefulWidget {
  /// Creates an [AppointmentActionButtons].
  const AppointmentActionButtons({
    super.key,
    required this.appointment,
    required this.userRole,
  });

  /// The current appointment.
  final Appointment appointment;

  /// The authenticated user's role.
  final UserRole userRole;

  @override
  ConsumerState<AppointmentActionButtons> createState() =>
      _AppointmentActionButtonsState();
}

class _AppointmentActionButtonsState
    extends ConsumerState<AppointmentActionButtons> {
  bool _isLoading = false;

  bool get _canCheckIn =>
      widget.appointment.status == AppointmentStatus.scheduled;

  bool get _canCancel =>
      widget.appointment.status == AppointmentStatus.scheduled ||
      widget.appointment.status == AppointmentStatus.checkedIn;

  bool get _canRevert =>
      widget.appointment.status == AppointmentStatus.checkedIn;

  bool get _canRestore =>
      widget.appointment.status == AppointmentStatus.cancelled;

  @override
  Widget build(BuildContext context) {
    final bool hasActions = _canCheckIn || _canCancel || _canRevert || _canRestore;
    if (!hasActions) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p24,
        vertical: AppSizes.p8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_canCheckIn)
            AppButton(
              labelText: AppStrings.checkIn,
              isLoading: _isLoading,
              onPressed: _isLoading ? null : () => _handleAction(_doCheckIn),
            ),
          if (_canCheckIn && (_canCancel || _canRevert || _canRestore))
            const SizedBox(height: AppSizes.p12),
          if (_canCancel)
            AppButton(
              labelText: AppStrings.cancelAppointment,
              variant: AppButtonVariant.danger,
              isLoading: _isLoading,
              onPressed: _isLoading ? null : () => _handleAction(_doCancel),
            ),
          if (_canCancel && (_canRevert || _canRestore))
            const SizedBox(height: AppSizes.p12),
          if (_canRevert)
            AppButton(
              labelText: AppStrings.revertToScheduled,
              variant: AppButtonVariant.warning,
              isLoading: _isLoading,
              onPressed: _isLoading ? null : () => _handleAction(_doRevert),
            ),
          if (_canRestore)
            AppButton(
              labelText: AppStrings.restoreToScheduled,
              variant: AppButtonVariant.warning,
              isLoading: _isLoading,
              onPressed: _isLoading ? null : () => _handleAction(_doRestore),
            ),
        ],
      ),
    );
  }

  Future<void> _handleAction(Future<void> Function() action) async {
    setState(() => _isLoading = true);
    try {
      await action();
    } on Exception catch (_) {
      if (mounted) {
        AppSnackbar.show(
          context,
          message: AppStrings.statusUpdateError,
          variant: AppSnackbarVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _doCheckIn() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmationDialog(
        title: AppStrings.checkInPatient,
        message: AppStrings.confirmCheckIn,
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(appointmentDetailControllerProvider(widget.appointment.id)
            .notifier)
        .checkIn();
    if (mounted) {
      AppSnackbar.show(
        context,
        message: AppStrings.statusUpdateSuccess,
        variant: AppSnackbarVariant.success,
      );
    }
  }

  Future<void> _doCancel() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmationDialog(
        title: AppStrings.cancelAppointment,
        message: AppStrings.confirmCancel,
        isDestructive: true,
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(appointmentDetailControllerProvider(widget.appointment.id)
            .notifier)
        .cancel();
    if (mounted) {
      AppSnackbar.show(
        context,
        message: AppStrings.statusUpdateSuccess,
        variant: AppSnackbarVariant.success,
      );
    }
  }

  Future<void> _doRevert() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmationDialog(
        title: AppStrings.revertToScheduled,
        message: AppStrings.confirmRevert,
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(appointmentDetailControllerProvider(widget.appointment.id)
            .notifier)
        .revertToScheduled();
    if (mounted) {
      AppSnackbar.show(
        context,
        message: AppStrings.statusUpdateSuccess,
        variant: AppSnackbarVariant.success,
      );
    }
  }

  Future<void> _doRestore() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmationDialog(
        title: AppStrings.restoreToScheduled,
        message: AppStrings.confirmRestore,
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(appointmentDetailControllerProvider(widget.appointment.id)
            .notifier)
        .revertToScheduled();
    if (mounted) {
      AppSnackbar.show(
        context,
        message: AppStrings.statusUpdateSuccess,
        variant: AppSnackbarVariant.success,
      );
    }
  }
}
