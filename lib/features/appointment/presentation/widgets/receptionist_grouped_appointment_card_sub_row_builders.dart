part of 'receptionist_grouped_appointment_card.dart';

/// Wide PC row layout for grouped sub-appointments.
class _GroupedSubAppointmentWideRow extends StatelessWidget {
  const _GroupedSubAppointmentWideRow({
    required this.item,
    required this.formattedTime,
    required this.dotColor,
    required this.isCancelled,
    required this.isPastScheduled,
    required this.isCompact,
    required this.canInteractWithMenu,
    this.onStatusChanged,
  });

  final AppointmentWithPatient item;
  final String formattedTime;
  final Color dotColor;
  final bool isCancelled;
  final bool isPastScheduled;
  final bool isCompact;
  final bool canInteractWithMenu;
  final VoidCallback? onStatusChanged;

  static const double _sessionTypeWidth = 130.0;
  static const double _statusWidth = 150.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clinic = ClinicColors.of(context);
    final subAppt = item.appointment;
    final Color timeColor = isCancelled
        ? clinic.textMuted
        : (subAppt.status == AppointmentStatus.checkedIn
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: isCompact ? 72.0 : 80.0,
          child: Text(
            formattedTime,
            style: AppTextStyles.captionBold.copyWith(
              color: timeColor,
              decoration: isCancelled ? TextDecoration.lineThrough : null,
              fontSize: isCompact ? 11 : 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Spacer(),
        SizedBox(
          width: _sessionTypeWidth,
          child: Text(
            subAppt.type.displayLabel,
            style: AppTextStyles.caption.copyWith(
              color: isCancelled
                  ? clinic.textMuted
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              decoration: isCancelled ? TextDecoration.lineThrough : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSizes.p12),
        SizedBox(
          width: _statusWidth,
          child: Align(
            alignment: Alignment.centerLeft,
            child: _GroupedStatusDot(
              color: dotColor,
              label: isPastScheduled
                  ? AppStrings.pastScheduledNeedsAction
                  : subAppt.status.displayLabel,
              icon: isPastScheduled
                  ? Icons.warning_amber_rounded
                  : (subAppt.status == AppointmentStatus.checkedIn
                      ? Icons.check_circle_rounded
                      : null),
              isCompact: isCompact,
            ),
          ),
        ),
        if (canInteractWithMenu) ...[
          const SizedBox(width: AppSizes.p8),
          AppointmentActionsTrailing(
            appointment: subAppt,
            onStatusChanged: onStatusChanged,
            showBadge: false,
          ),
        ],
      ],
    );
  }
}

/// Mobile compact row layout for grouped sub-appointments.
class _GroupedSubAppointmentMobileRow extends StatelessWidget {
  const _GroupedSubAppointmentMobileRow({
    required this.item,
    required this.formattedTime,
    required this.dotColor,
    required this.isCancelled,
    required this.isPastScheduled,
    required this.isCompact,
    required this.canInteractWithMenu,
    this.onStatusChanged,
  });

  final AppointmentWithPatient item;
  final String formattedTime;
  final Color dotColor;
  final bool isCancelled;
  final bool isPastScheduled;
  final bool isCompact;
  final bool canInteractWithMenu;
  final VoidCallback? onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clinic = ClinicColors.of(context);
    final subAppt = item.appointment;
    final Color timeColor = isCancelled
        ? clinic.textMuted
        : (subAppt.status == AppointmentStatus.checkedIn
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          formattedTime,
          style: AppTextStyles.captionBold.copyWith(
            color: timeColor,
            decoration: isCancelled ? TextDecoration.lineThrough : null,
            fontSize: isCompact ? 11 : 12,
          ),
        ),
        const SizedBox(width: AppSizes.p8),
        Expanded(
          child: Text(
            subAppt.type.displayLabel,
            style: AppTextStyles.caption.copyWith(
              color: isCancelled
                  ? clinic.textMuted
                  : theme.colorScheme.onSurfaceVariant,
              decoration: isCancelled ? TextDecoration.lineThrough : null,
              fontSize: isCompact ? 11 : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSizes.p6),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isCompact ? 110 : 130),
          child: _GroupedStatusDot(
            color: dotColor,
            label: isPastScheduled
                ? AppStrings.pastScheduledNeedsAction
                : subAppt.status.displayLabel,
            icon: isPastScheduled
                ? Icons.warning_amber_rounded
                : (subAppt.status == AppointmentStatus.checkedIn
                    ? Icons.check_circle_rounded
                    : null),
            isCompact: isCompact,
          ),
        ),
        if (canInteractWithMenu) ...[
          const SizedBox(width: AppSizes.p4),
          AppointmentActionsTrailing(
            appointment: subAppt,
            onStatusChanged: onStatusChanged,
            showBadge: false,
          ),
        ],
      ],
    );
  }
}
