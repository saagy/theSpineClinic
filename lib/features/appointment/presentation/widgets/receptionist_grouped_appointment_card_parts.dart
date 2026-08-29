part of 'receptionist_grouped_appointment_card.dart';

/// Patient header row inside [ReceptionistGroupedAppointmentCard].
/// Layout: [Clock] [Avatar] [Name & "Dual session" under it] [Three-dot menu]
class _GroupedCardHeader extends StatelessWidget {
  const _GroupedCardHeader({
    required this.patient,
    required this.scheduledAt,
    required this.allCancelled,
    required this.allCheckedIn,
    required this.isCompact,
    required this.isAuthorizedStaff,
    required this.trailingMenu,
  });

  final Patient patient;
  final DateTime scheduledAt;
  final bool allCancelled;
  final bool allCheckedIn;
  final bool isCompact;
  final bool isAuthorizedStaff;
  final Widget? trailingMenu;

  static const double _wideBreakpoint = 500.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clinic = ClinicColors.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= _wideBreakpoint;
        final double leadingWidth = isWide
            ? (isCompact ? 54.0 : 64.0)
            : (isCompact ? 38.0 : 40.0);
        final double spacingBetween = isWide ? AppSizes.p12 : AppSizes.p6;
        final double avatarToTextSpacing = isWide ? AppSizes.p8 : AppSizes.p6;
        final double avatarRadius = isCompact ? 12.0 : 14.0;

        final nameStyle = AppTextStyles.bodyBold.copyWith(
          color: allCancelled ? clinic.textMuted : theme.colorScheme.onSurface,
          decoration: allCancelled ? TextDecoration.lineThrough : null,
          fontSize: isCompact ? 13 : null,
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _GroupedCardTimeWidget(
              scheduledAt: scheduledAt,
              allCancelled: allCancelled,
              allCheckedIn: allCheckedIn,
              isCompact: isCompact,
              isWide: isWide,
              fixedWidth: leadingWidth,
            ),
            SizedBox(width: spacingBetween),
            AppAvatar(
              name: patient.fullName,
              radius: avatarRadius,
              color: allCancelled ? clinic.textMuted : null,
            ),
            SizedBox(width: avatarToTextSpacing),
            Expanded(
              child: isCompact
                  ? AutoSizeText(
                      patient.fullName,
                      style: nameStyle,
                      maxLines: 1,
                      minFontSize: 10,
                      overflow: TextOverflow.ellipsis,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AutoSizeText(
                          patient.fullName,
                          style: nameStyle,
                          maxLines: 1,
                          minFontSize: 10,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSizes.p2),
                        Text(
                          AppStrings.dualSession,
                          style: AppTextStyles.caption.copyWith(
                            color: allCancelled
                                ? clinic.textMuted
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
            ),
            if (isAuthorizedStaff && trailingMenu != null) ...[
              const SizedBox(width: AppSizes.p4),
              trailingMenu!,
            ],
          ],
        );
      },
    );
  }
}

/// Time widget for the grouped card header on the left.
class _GroupedCardTimeWidget extends StatelessWidget {
  const _GroupedCardTimeWidget({
    required this.scheduledAt,
    required this.allCancelled,
    required this.allCheckedIn,
    required this.isCompact,
    this.isWide = false,
    this.fixedWidth,
  });

  final DateTime scheduledAt;
  final bool allCancelled;
  final bool allCheckedIn;
  final bool isCompact;
  final bool isWide;
  final double? fixedWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clinic = ClinicColors.of(context);
    final Color timeColor = allCancelled
        ? clinic.textMuted
        : (allCheckedIn
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface);

    final Widget timeWidget;
    if (isWide) {
      timeWidget = Text(
        DateFormat('hh:mm a').format(scheduledAt),
        maxLines: 1,
        softWrap: false,
        style: AppTextStyles.captionBold.copyWith(
          color: timeColor,
          fontSize: isCompact ? 11 : 12,
        ),
      );
    } else if (isCompact) {
      timeWidget = Text(
        DateFormat('hh:mm a').format(scheduledAt),
        maxLines: 1,
        softWrap: false,
        style: AppTextStyles.captionBold.copyWith(
          color: timeColor,
          fontSize: 11,
        ),
      );
    } else {
      timeWidget = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            DateFormat('hh:mm').format(scheduledAt),
            maxLines: 1,
            softWrap: false,
            style: AppTextStyles.captionBold.copyWith(
              color: timeColor,
              fontSize: 13,
            ),
          ),
          Text(
            DateFormat('a').format(scheduledAt),
            maxLines: 1,
            softWrap: false,
            style: AppTextStyles.caption.copyWith(
              color: timeColor,
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
