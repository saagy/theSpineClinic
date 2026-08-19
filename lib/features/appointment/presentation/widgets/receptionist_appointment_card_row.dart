part of 'receptionist_appointment_card.dart';

/// Responsive card row supporting mobile and PC/wide layouts, in standard
/// or compact density with column-aligned fields on wide viewports.
class _AppointmentCardRow extends StatelessWidget {
  const _AppointmentCardRow({
    required this.item,
    required this.showDate,
    required this.style,
    required this.statusBadge,
    required this.isPastScheduled,
    required this.clinic,
    required this.enableMenu,
    required this.isCompact,
    this.onStatusChanged,
  });

  final AppointmentWithPatient item;
  final bool showDate;
  final AppointmentStatusStyle style;
  final AppointmentBadgeColors statusBadge;
  final bool isPastScheduled;
  final ClinicColors clinic;
  final bool enableMenu;
  final bool isCompact;
  final VoidCallback? onStatusChanged;

  static const double _sessionTypeWidth = 130.0;
  static const double _statusWidth = 150.0;
  static const double _wideBreakpoint = 500.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= _wideBreakpoint;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _TimeAvatar(
                item: item,
                showDate: showDate,
                style: style,
                isCompact: isCompact,
                fixedWidth: isCompact ? 88.0 : 96.0,
              ),
              const SizedBox(width: AppSizes.p12),
              Expanded(
                child: Text(
                  item.patient.fullName,
                  style: AppTextStyles.bodyBold.copyWith(
                    color: style.nameColor,
                    decoration: style.nameDecoration,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSizes.p12),
              SizedBox(
                width: _sessionTypeWidth,
                child: Text(
                  item.appointment.type.displayLabel,
                  style: AppTextStyles.caption.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                  child: _StatusDot(
                    color: isPastScheduled
                        ? clinic.warning
                        : statusBadge.textColor,
                    label: isPastScheduled
                        ? AppStrings.pastScheduledNeedsAction
                        : item.appointment.status.displayLabel,
                    icon: isPastScheduled ? Icons.warning_amber_rounded : null,
                    isCompact: isCompact,
                  ),
                ),
              ),
              if (enableMenu) ...[
                const SizedBox(width: AppSizes.p8),
                AppointmentActionsTrailing(
                  appointment: item.appointment,
                  onStatusChanged: onStatusChanged,
                  showBadge: false,
                ),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _TimeAvatar(
              item: item,
              showDate: showDate,
              style: style,
              isCompact: isCompact,
            ),
            const SizedBox(width: AppSizes.p8),
            Expanded(
              child: _NameStatus(
                item: item,
                style: style,
                statusBadge: statusBadge,
                isPastScheduled: isPastScheduled,
                clinic: clinic,
                isCompact: isCompact,
              ),
            ),
            if (enableMenu) ...[
              const SizedBox(width: AppSizes.p8),
              AppointmentActionsTrailing(
                appointment: item.appointment,
                onStatusChanged: onStatusChanged,
                showBadge: false,
              ),
            ],
          ],
        );
      },
    );
  }
}
