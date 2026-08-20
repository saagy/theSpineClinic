part of 'receptionist_appointment_card.dart';

/// Long-press context menu for individual appointment cards.
///
/// Shows the same status-change actions as the three-dot trailing menu
/// but positioned exactly where the user pressed.
mixin _ReceptionistAppointmentCardMenu
    on ConsumerState<ReceptionistAppointmentCard> {
  bool _isMenuProcessing = false;
  AppointmentStatus? _optimisticStatus;

  /// Opens a context menu at [globalPosition] with status actions.
  Future<void> showLongPressMenu(Offset globalPosition) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null || _isMenuProcessing) return;
    if (user.role == UserRole.doctor) {
      final canAccess = await ref.read(
        canAccessAppointmentProvider(
          appointmentId: widget.item.appointment.id,
          patientId: widget.item.patient.id,
        ).future,
      );
      if (!canAccess || !mounted) return;
    } else if (user.role != UserRole.receptionist &&
        user.role != UserRole.superAdmin) {
      return;
    }

    final status = widget.item.appointment.status;
    final bool hasActions = status == AppointmentStatus.scheduled ||
        status == AppointmentStatus.checkedIn ||
        status == AppointmentStatus.cancelled;
    if (!hasActions) return;

    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(globalPosition, globalPosition),
      overlay.localToGlobal(Offset.zero) & overlay.size,
    );

    final String? selected = await showMenu<String>(
      context: context,
      position: position,
      color: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.r12)),
      ),
      elevation: 1,
      items: _menuItems(status),
    );

    if (selected == null || !mounted) return;
    await _handleSelection(selected);
  }

  List<PopupMenuItem<String>> _menuItems(AppointmentStatus status) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ClinicColors clinic = ClinicColors.of(context);
    return switch (status) {
      AppointmentStatus.scheduled => [
          _item('check_in', Icons.check_circle_outline_rounded,
              clinic.success, AppStrings.checkIn),
          _item('cancel', Icons.close_rounded, cs.error,
              AppStrings.cancelAppointment),
        ],
      AppointmentStatus.checkedIn => [
          _item('revert', Icons.undo_rounded, cs.onSurfaceVariant,
              AppStrings.revertToScheduled),
          _item('cancel', Icons.close_rounded, cs.error,
              AppStrings.cancelAppointment),
        ],
      AppointmentStatus.cancelled => [
          _item('restore', Icons.refresh_rounded, clinic.success,
              AppStrings.restoreAppointment),
        ],
    };
  }

  PopupMenuItem<String> _item(
    String value, IconData icon, Color iconColor, String label,
  ) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return PopupMenuItem<String>(
      value: value,
      height: AppSizes.buttonHeightSmall,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: AppSizes.p8),
          Text(label, style: AppTextStyles.bodyMedium.copyWith(
            color: cs.onSurface,
          )),
        ],
      ),
    );
  }

  Future<void> _handleSelection(String value) async {
    if (_isMenuProcessing) return;
    setState(() => _isMenuProcessing = true);
    try {
      final apptId = widget.item.appointment.id;
      switch (value) {
        case 'check_in':
          await _setStatus(apptId, AppointmentStatus.checkedIn);
        case 'revert' || 'restore':
          await _setStatus(apptId, AppointmentStatus.scheduled);
        case 'cancel':
          final bool? confirmed = await showDialog<bool>(
            context: context,
            builder: (_) => const ConfirmationDialog(
              title: AppStrings.cancelAppointment,
              message: AppStrings.confirmCancel,
              isDestructive: true,
            ),
          );
          if (confirmed == true && mounted) {
            await _setStatus(apptId, AppointmentStatus.cancelled);
          }
      }
    } finally {
      if (mounted) setState(() => _isMenuProcessing = false);
    }
  }

  Future<void> _setStatus(String id, AppointmentStatus status) async {
    setState(() {
      _isMenuProcessing = true;
      _optimisticStatus = status;
    });
    ref
        .read(receptionistAppointmentsProvider.notifier)
        .changeStatus(id, status);
    ref
        .read(doctorScheduleProvider.notifier)
        .changeStatus(id, status);
    ref
        .read(allAppointmentsProvider.notifier)
        .updateStatus(id, status);
    try {
      final result = await ref
          .read(appointmentRepositoryProvider)
          .updateAppointmentStatus(id, status);
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
          _revertProviderState(id, widget.item.appointment.status);
          if (mounted) setState(() => _optimisticStatus = null);
          AppSnackbar.show(
            context,
            message: AppStrings.fromKey(error.userMessageKey),
            variant: AppSnackbarVariant.error,
          );
        },
      );
    } catch (_) {
      _revertProviderState(id, widget.item.appointment.status);
      if (mounted) setState(() => _optimisticStatus = null);
    } finally {
      if (mounted) setState(() => _isMenuProcessing = false);
    }
  }

  void _revertProviderState(String apptId, AppointmentStatus originalStatus) {
    ref
        .read(receptionistAppointmentsProvider.notifier)
        .changeStatus(apptId, originalStatus);
    ref
        .read(doctorScheduleProvider.notifier)
        .changeStatus(apptId, originalStatus);
    ref
        .read(allAppointmentsProvider.notifier)
        .updateStatus(apptId, originalStatus);
  }

  void _invalidateCaches() {
    final String patientId = widget.item.appointment.patientId;
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
