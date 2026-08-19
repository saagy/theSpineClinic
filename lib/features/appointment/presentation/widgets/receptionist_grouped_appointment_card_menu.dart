part of 'receptionist_grouped_appointment_card.dart';

/// Context menu actions and dialog handlers for grouped appointments.
mixin _ReceptionistGroupedAppointmentCardMenu
    on ConsumerState<ReceptionistGroupedAppointmentCard> {
  bool _isProcessing = false;

  Widget buildGroupContextMenu({
    required BuildContext context,
    required List<AppointmentWithPatient> items,
    required bool hasScheduled,
    required bool hasCheckedIn,
    required bool allCancelled,
    required bool hasCancellable,
  }) {
    final theme = Theme.of(context);
    final clinic = ClinicColors.of(context);

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz_rounded,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      splashRadius: AppSizes.iconDefault,
      color: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.r12)),
      ),
      elevation: 1,
      position: PopupMenuPosition.under,
      enabled: !_isProcessing,
      onSelected: (value) {
        if (value == 'restore_all') {
          final cancelledIds = items
              .where((i) => i.appointment.status == AppointmentStatus.cancelled)
              .map((i) => i.appointment.id)
              .toList();
          _setGroupStatus(cancelledIds, AppointmentStatus.scheduled);
        } else if (value == 'check_in_all') {
          final scheduledIds = items
              .where((i) => i.appointment.status == AppointmentStatus.scheduled)
              .map((i) => i.appointment.id)
              .toList();
          _setGroupStatus(scheduledIds, AppointmentStatus.checkedIn);
        } else if (value == 'cancel_all') {
          final cancellableIds = items
              .where((i) => i.appointment.status != AppointmentStatus.cancelled)
              .map((i) => i.appointment.id)
              .toList();
          _confirmCancelAll(cancellableIds);
        } else if (value == 'revert_all') {
          final checkedInIds = items
              .where((i) => i.appointment.status == AppointmentStatus.checkedIn)
              .map((i) => i.appointment.id)
              .toList();
          _setGroupStatus(checkedInIds, AppointmentStatus.scheduled);
        }
      },
      itemBuilder: (context) {
        if (allCancelled) {
          return [
            _menuItem(
              'restore_all',
              Icons.refresh_rounded,
              clinic.success,
              AppStrings.restoreAllSessions,
            ),
          ];
        }
        return [
          if (hasScheduled)
            _menuItem(
              'check_in_all',
              Icons.check_circle_outline_rounded,
              clinic.success,
              AppStrings.checkInAllSessions,
            ),
          if (hasCheckedIn)
            _menuItem(
              'revert_all',
              Icons.undo_rounded,
              theme.colorScheme.onSurfaceVariant,
              AppStrings.revertAllSessions,
            ),
          if (hasCancellable)
            _menuItem(
              'cancel_all',
              Icons.close_rounded,
              theme.colorScheme.error,
              AppStrings.cancelAllSessions,
            ),
        ];
      },
    );
  }

  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    Color iconColor,
    String label,
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
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancelAll(List<String> ids) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmationDialog(
        title: AppStrings.cancelAllSessions,
        message: AppStrings.confirmCancelAllSessions,
        isDestructive: true,
      ),
    );
    if (confirmed == true && mounted) {
      await _setGroupStatus(ids, AppointmentStatus.cancelled);
    }
  }

  Future<void> _setGroupStatus(
    List<String> ids,
    AppointmentStatus status,
  ) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await ref
          .read(receptionistAppointmentsProvider.notifier)
          .changeGroupStatus(ids, status);
      if (!mounted) return;
      AppSnackbar.show(
        context,
        message: AppStrings.statusUpdateSuccess,
        variant: AppSnackbarVariant.success,
      );
      widget.onStatusChanged?.call();
    } catch (error) {
      if (mounted) {
        AppSnackbar.show(
          context,
          message: AppStrings.errorUpdatingSessionStatus,
          variant: AppSnackbarVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
