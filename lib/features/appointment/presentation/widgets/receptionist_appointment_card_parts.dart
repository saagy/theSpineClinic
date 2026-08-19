part of 'receptionist_appointment_card.dart';

/// Time column + avatar leading widget.
class _TimeAvatar extends StatelessWidget {
  const _TimeAvatar({
    required this.item,
    required this.showDate,
    required this.style,
    required this.isCompact,
    this.fixedWidth,
  });

  final AppointmentWithPatient item;
  final bool showDate;
  final AppointmentStatusStyle style;
  final bool isCompact;
  final double? fixedWidth;

  @override
  Widget build(BuildContext context) {
    final DateTime t = item.appointment.scheduledAt.toLocal();
    final double avatarRadius = isCompact ? 11.0 : AppSizes.avatarSmall / 2;

    Widget timeWidget;
    if (isCompact) {
      timeWidget = Text(
        DateFormat('hh:mm a').format(t),
        maxLines: 1,
        softWrap: false,
        style: AppTextStyles.captionBold.copyWith(
          color: style.timeColor,
          fontSize: 11,
        ),
      );
    } else {
      timeWidget = Column(
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
      );
    }

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        timeWidget,
        SizedBox(width: isCompact ? AppSizes.p6 : AppSizes.p8),
        AppAvatar(
          name: item.patient.fullName,
          radius: avatarRadius,
          color: style.avatarBg,
        ),
      ],
    );

    if (fixedWidth != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(minWidth: fixedWidth!),
        child: content,
      );
    }
    return content;
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
    required this.isCompact,
  });

  final AppointmentWithPatient item;
  final AppointmentStatusStyle style;
  final AppointmentBadgeColors statusBadge;
  final bool isPastScheduled;
  final ClinicColors clinic;
  final bool isCompact;

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
            fontSize: isCompact ? 13 : null,
          ),
          maxLines: 1,
          minFontSize: 10,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: isCompact ? 0 : AppSizes.p2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              flex: 2,
              child: Text(
                item.appointment.type.displayLabel,
                style: AppTextStyles.caption.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: isCompact ? 10 : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSizes.p6),
            Flexible(
              flex: 3,
              child: _StatusDot(
                color: isPastScheduled ? clinic.warning : statusBadge.textColor,
                label: isPastScheduled
                    ? AppStrings.pastScheduledNeedsAction
                    : status.displayLabel,
                icon: isPastScheduled ? Icons.warning_amber_rounded : null,
                isCompact: isCompact,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Colour-coded dot + coloured text — no background pill.
class _StatusDot extends StatelessWidget {
  const _StatusDot({
    required this.color,
    required this.label,
    this.icon,
    this.isCompact = false,
  });

  final Color color;
  final String label;
  final IconData? icon;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon == null)
          Container(
            width: isCompact ? 5 : AppSizes.p6,
            height: isCompact ? 5 : AppSizes.p6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          )
        else
          Icon(
            icon,
            color: color,
            size: isCompact ? 13 : AppSizes.iconSmall,
          ),
        const SizedBox(width: AppSizes.p4),
        Flexible(
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontSize: isCompact ? 10 : 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
