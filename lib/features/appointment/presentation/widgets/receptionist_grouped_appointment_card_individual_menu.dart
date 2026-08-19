part of 'receptionist_grouped_appointment_card.dart';

/// Individual sub-appointment context menu on long-press.
extension _ReceptionistIndividualAppointmentMenu
    on _ReceptionistGroupedAppointmentCardState {
  Future<void> showIndividualStatusMenu(
    Appointment appointment,
    Offset globalPosition,
  ) async {
    final theme = Theme.of(context);
    final clinic = ClinicColors.of(context);
    final status = appointment.status;

    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(globalPosition, globalPosition),
      overlay.localToGlobal(Offset.zero) & overlay.size,
    );

    final String? selectedValue = await showMenu<String>(
      context: context,
      position: position,
      color: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.r12)),
      ),
      elevation: 1,
      items: [
        if (status == AppointmentStatus.scheduled) ...[
          _menuItem(
            'check_in',
            Icons.check_circle_outline_rounded,
            clinic.success,
            AppStrings.checkIn,
          ),
          _menuItem(
            'cancel',
            Icons.close_rounded,
            theme.colorScheme.error,
            AppStrings.cancelAppointment,
          ),
        ],
        if (status == AppointmentStatus.checkedIn) ...[
          _menuItem(
            'revert',
            Icons.undo_rounded,
            theme.colorScheme.onSurfaceVariant,
            AppStrings.revertToScheduled,
          ),
          _menuItem(
            'cancel',
            Icons.close_rounded,
            theme.colorScheme.error,
            AppStrings.cancelAppointment,
          ),
        ],
        if (status == AppointmentStatus.cancelled) ...[
          _menuItem(
            'restore',
            Icons.refresh_rounded,
            clinic.success,
            AppStrings.restoreAppointment,
          ),
        ],
      ],
    );

    if (selectedValue == null || !mounted) return;

    if (selectedValue == 'check_in') {
      _setGroupStatus([appointment.id], AppointmentStatus.checkedIn);
    } else if (selectedValue == 'revert' || selectedValue == 'restore') {
      _setGroupStatus([appointment.id], AppointmentStatus.scheduled);
    } else if (selectedValue == 'cancel') {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => const ConfirmationDialog(
          title: AppStrings.cancelAppointment,
          message: AppStrings.confirmCancel,
          isDestructive: true,
        ),
      );
      if (confirmed == true && mounted) {
        _setGroupStatus([appointment.id], AppointmentStatus.cancelled);
      }
    }
  }
}
