part of 'receptionist_appointment_card.dart';

/// Compact time + patient name + session type widget.
class _CompactAppointmentInfo extends StatelessWidget {
  const _CompactAppointmentInfo({
    required this.item,
    required this.showDate,
    required this.style,
  });

  final AppointmentWithPatient item;
  final bool showDate;
  final AppointmentStatusStyle style;

  @override
  Widget build(BuildContext context) {
    final DateTime t = item.appointment.scheduledAt.toLocal();
    final String timeStr = DateFormat('h:mm a').format(t);
    final String dateStr =
        showDate ? '${DateFormat('MMM d').format(t)} · ' : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              timeStr,
              style: AppTextStyles.captionBold.copyWith(
                color: style.timeColor,
                fontFeatures: AppTextStyles.number.fontFeatures,
              ),
            ),
            const SizedBox(width: AppSizes.p8),
            Expanded(
              child: AutoSizeText(
                item.patient.fullName,
                style: AppTextStyles.bodyBold.copyWith(
                  color: style.nameColor,
                  decoration: style.nameDecoration,
                ),
                maxLines: 1,
                minFontSize: 11,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.p4),
        Text(
          '$dateStr${item.appointment.type.displayLabel}',
          style: AppTextStyles.caption.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Compact status dot + trailing action menu.
class _CompactStatusAndActions extends StatelessWidget {
  const _CompactStatusAndActions({
    required this.item,
    required this.style,
    required this.statusBadge,
    required this.isPastScheduled,
    required this.clinic,
    required this.enableMenu,
    this.onStatusChanged,
  });

  final AppointmentWithPatient item;
  final AppointmentStatusStyle style;
  final AppointmentBadgeColors statusBadge;
  final bool isPastScheduled;
  final ClinicColors clinic;
  final bool enableMenu;
  final VoidCallback? onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final AppointmentStatus status = item.appointment.status;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _StatusDot(
          color: isPastScheduled ? clinic.warning : statusBadge.textColor,
          label: isPastScheduled
              ? AppStrings.pastScheduledNeedsAction
              : status.displayLabel,
          icon: isPastScheduled ? Icons.warning_amber_rounded : null,
        ),
        if (enableMenu) ...[
          const SizedBox(width: AppSizes.p4),
          AppointmentActionsTrailing(
            appointment: item.appointment,
            onStatusChanged: onStatusChanged,
            showBadge: false,
          ),
        ],
      ],
    );
  }
}

/// Colour-coded dot + coloured text — no background pill.
class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color, required this.label, this.icon});
  final Color color;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon == null)
          Container(
            width: AppSizes.p6,
            height: AppSizes.p6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          )
        else
          Icon(icon, color: color, size: AppSizes.iconSmall),
        const SizedBox(width: AppSizes.p4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
