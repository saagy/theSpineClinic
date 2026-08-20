part of 'appointment_actions_trailing.dart';

mixin _AppointmentActionsTrailingHandlers
    on ConsumerState<AppointmentActionsTrailing> {
  bool _isProcessing = false;
  AppointmentStatus? _optimisticStatus;

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
    if (_isProcessing) return;
    final bool canUpdate = await _canUpdateStatus();
    if (!canUpdate) return;
    setState(() {
      _isProcessing = true;
      _optimisticStatus = status;
    });
    ref
        .read(receptionistAppointmentsProvider.notifier)
        .changeStatus(widget.appointment.id, status);
    ref
        .read(doctorScheduleProvider.notifier)
        .changeStatus(widget.appointment.id, status);
    ref
        .read(allAppointmentsProvider.notifier)
        .updateStatus(widget.appointment.id, status);
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
        failure: (error) {
          if (mounted) setState(() => _optimisticStatus = null);
          AppSnackbar.show(
            context,
            message: AppStrings.fromKey(error.userMessageKey),
            variant: AppSnackbarVariant.error,
          );
        },
      );
    } catch (_) {
      if (mounted) setState(() => _optimisticStatus = null);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<bool> _canUpdateStatus() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return false;
    if (user.role == UserRole.doctor) {
      return ref.read(
        canAccessAppointmentProvider(
          appointmentId: widget.appointment.id,
          patientId: widget.appointment.patientId,
        ).future,
      );
    }
    return user.role == UserRole.receptionist ||
        user.role == UserRole.superAdmin;
  }

  void _invalidateCaches() {
    final String patientId = widget.appointment.patientId;
    ref.invalidate(todayAppointmentsProvider);
    ref.read(allAppointmentsProvider.notifier).refresh();
    ref.invalidate(patientAppointmentsProvider(patientId));
    ref.invalidate(patientDetailProvider(patientId));
    ref.invalidate(futureScheduledAppointmentsCountProvider(patientId));
    ref.invalidate(availablePackageBalanceProvider(patientId));
    ref.read(doctorScheduleProvider.notifier).refresh();
    ref.invalidate(patientListProvider);
    widget.onStatusChanged?.call();
  }
}
