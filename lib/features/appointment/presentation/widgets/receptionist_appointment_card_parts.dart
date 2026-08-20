part of 'receptionist_appointment_card.dart';

/// Time & date leading column widget.
class _TimeWidget extends StatelessWidget {
  const _TimeWidget({
    required this.item,
    required this.showDate,
    required this.style,
    required this.isCompact,
    this.isWide = false,
    this.fixedWidth,
  });

  final AppointmentWithPatient item;
  final bool showDate;
  final AppointmentStatusStyle style;
  final bool isCompact;
  final bool isWide;
  final double? fixedWidth;

  @override
  Widget build(BuildContext context) {
    final DateTime t = item.appointment.scheduledAt.toLocal();
    final bool isCurrentYear = t.year == DateTime.now().year;
    final String dateStr = isCurrentYear
        ? DateFormat('MMM d').format(t)
        : DateFormat('MMM d, yy').format(t);

    final Widget timeWidget;
    if (isWide && showDate) {
      timeWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dateStr,
            maxLines: 1,
            softWrap: false,
            style: AppTextStyles.caption.copyWith(
              color: style.timeColor,
              fontSize: isCompact ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSizes.p6),
          Text(
            DateFormat('hh:mm a').format(t),
            maxLines: 1,
            softWrap: false,
            style: AppTextStyles.captionBold.copyWith(
              color: style.timeColor,
              fontSize: isCompact ? 11 : 12,
            ),
          ),
        ],
      );
    } else if (isCompact) {
      timeWidget = showDate
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  maxLines: 1,
                  softWrap: false,
                  style: AppTextStyles.caption.copyWith(
                    color: style.timeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
                Text(
                  DateFormat('hh:mm a').format(t),
                  maxLines: 1,
                  softWrap: false,
                  style: AppTextStyles.captionBold.copyWith(
                    color: style.timeColor,
                    fontSize: 11,
                    height: 1.1,
                  ),
                ),
              ],
            )
          : Text(
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
              dateStr,
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

    if (fixedWidth != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(minWidth: fixedWidth!),
        child: timeWidget,
      );
    }
    return timeWidget;
  }
}
