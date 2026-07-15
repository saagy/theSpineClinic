part of 'receptionist_appointment_card.dart';

/// Time column + avatar leading widget.
class _TimeAvatar extends StatelessWidget {
  const _TimeAvatar({
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (showDate)
              Text(
                DateFormat('MMM d').format(t),
                maxLines: 1,
                softWrap: false,
                style: AppTextStyles.caption.copyWith(
                  color: style.timeColor,
                  fontSize: 11,
                ),
              ),
            Text(
              DateFormat('hh:mm').format(t),
              maxLines: 1,
              softWrap: false,
              style: AppTextStyles.captionBold.copyWith(
                color: style.timeColor,
                fontSize: 13,
              ),
            ),
            Text(
              DateFormat('a').format(t),
              maxLines: 1,
              softWrap: false,
              style: AppTextStyles.caption.copyWith(
                color: style.timeColor,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(width: AppSizes.p8),
        AppAvatar(
          name: item.patient.fullName,
          radius: AppSizes.avatarSmall / 2,
          color: style.avatarBg,
        ),
      ],
    );
  }
}

/// Name line + session type + status dot row.
class _NameStatus extends StatelessWidget {
  const _NameStatus({
    required this.item,
    required this.style,
    required this.statusBadge,
    required this.isPastScheduled,
    required this.clinic,
  });
  final AppointmentWithPatient item;
  final AppointmentStatusStyle style;
  final AppointmentBadgeColors statusBadge;
  final bool isPastScheduled;
  final ClinicColors clinic;

  @override
  Widget build(BuildContext context) {
    final AppointmentStatus status = item.appointment.status;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AutoSizeText(
          item.patient.fullName,
          style: AppTextStyles.bodyBold.copyWith(
            color: style.nameColor,
            decoration: style.nameDecoration,
          ),
          maxLines: 1,
          minFontSize: 11,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSizes.p2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                item.appointment.type.displayLabel,
                style: AppTextStyles.caption.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSizes.p6),
            _StatusDot(
              color: isPastScheduled ? clinic.warning : statusBadge.textColor,
              label: isPastScheduled
                  ? AppStrings.pastScheduledNeedsAction
                  : status.displayLabel,
              icon: isPastScheduled ? Icons.warning_amber_rounded : null,
            ),
          ],
        ),
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
