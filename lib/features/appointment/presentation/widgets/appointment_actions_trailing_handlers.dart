part of 'appointment_actions_trailing.dart';

mixin _AppointmentActionsTrailingHandlers
    on ConsumerState<AppointmentActionsTrailing> {
  bool _isProcessing = false;

  Future<void> _handleCheckIn() => _setStatus(AppointmentStatus.checkedIn);

  Future<void> _handleRevertToScheduled() =>
      _setStatus(AppointmentStatus.scheduled);

  Future<void> _handleRestore() => _setStatus(AppointmentStatus.scheduled);

  Future<void> _handleCancel() async {
    if (_isProcessing) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmationDialog(
        title: AppStrings.cancelAppointment,
        message: AppStrings.confirmCancel,
        isDestructive: true,
      ),
    );
    if (confirmed == true && mounted) {
      await _setStatus(AppointmentStatus.cancelled);
    }
  }

  Future<void> _setStatus(AppointmentStatus status) async {
    if (_isProcessing || !_canUpdateStatus()) return;
    setState(() => _isProcessing = true);
    try {
      final result = await ref
          .read(appointmentRepositoryProvider)
          .updateAppointmentStatus(widget.appointment.id, status);
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
        failure: (error) => AppSnackbar.show(
          context,
          message: AppStrings.fromKey(error.userMessageKey),
          variant: AppSnackbarVariant.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  bool _canUpdateStatus() {
    final user = ref.read(currentUserProvider).value;
    return user != null &&
        (user.role == UserRole.receptionist ||
            user.role == UserRole.superAdmin ||
            user.role == UserRole.doctor);
  }

  void _invalidateCaches() {
    final String patientId = widget.appointment.patientId;
    ref.invalidate(todayAppointmentsProvider);
    ref.read(allAppointmentsProvider.notifier).refresh();
    ref.invalidate(patientAppointmentsProvider(patientId));
    ref.invalidate(patientDetailProvider(patientId));
    ref.invalidate(futureScheduledAppointmentsCountProvider(patientId));
    ref.invalidate(availablePackageBalanceProvider(patientId));
    ref.invalidate(doctorScheduleProvider);
    ref.invalidate(patientListProvider);
    widget.onStatusChanged?.call();
  }
}
