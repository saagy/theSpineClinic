part of 'receptionist_appointment_card.dart';

/// Responsive card row supporting mobile and PC/wide layouts, in standard
/// or compact density with column-aligned fields on wide viewports.
class _AppointmentCardRow extends StatelessWidget {
  const _AppointmentCardRow({
    required this.item,
    required this.status,
    required this.showDate,
    required this.style,
    required this.statusBadge,
    required this.isPastScheduled,
    required this.clinic,
    required this.enableMenu,
    required this.isCompact,
    required this.isPatientContext,
    this.onStatusChanged,
  });

  final AppointmentWithPatient item;
  final AppointmentStatus status;
  final bool showDate;
  final AppointmentStatusStyle style;
  final AppointmentBadgeColors statusBadge;
  final bool isPastScheduled;
  final ClinicColors clinic;
  final bool enableMenu;
  final bool isCompact;
  final bool isPatientContext;
  final VoidCallback? onStatusChanged;

  static const double _sessionTypeWidth = 130.0;
  static const double _statusWidth = 150.0;
  static const double _wideBreakpoint = 500.0;

  @override
  Widget build(BuildContext context) {
    final double avatarRadius = isCompact ? 12.0 : 14.0;
    final String avatarName = isPatientContext
        ? (item.doctorName ?? AppStrings.doctor)
        : item.patient.fullName;
    final IconData? avatarIcon = isPatientContext
        ? LucideIcons.stethoscope
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= _wideBreakpoint;
        if (isWide) {
          final String title = isPatientContext
              ? (item.doctorName != null && item.doctorName!.trim().isNotEmpty
                  ? (item.doctorName!.toLowerCase().startsWith('dr')
                      ? item.doctorName!
                      : 'Dr. ${item.doctorName}')
                  : AppStrings.noDoctorsAssigned)
              : item.patient.fullName;

          final double leadingWidth = isCompact
              ? (showDate ? 116.0 : 54.0)
              : (showDate ? 120.0 : 64.0);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _TimeWidget(
                item: item,
                showDate: showDate,
                style: style,
                isCompact: isCompact,
                isWide: isWide,
                fixedWidth: leadingWidth,
              ),
              const SizedBox(width: AppSizes.p12),
              Expanded(
                child: Row(
                  children: [
                    AppAvatar(
                      name: avatarName,
                      radius: avatarRadius,
                      color: style.avatarBg,
                      icon: avatarIcon,
                    ),
                    const SizedBox(width: AppSizes.p8),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.bodyBold.copyWith(
                          color: style.nameColor,
                          decoration: style.nameDecoration,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
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
                        : status.displayLabel,
                    icon: isPastScheduled
                        ? Icons.warning_amber_rounded
                        : (status == AppointmentStatus.checkedIn
                            ? Icons.check_circle_rounded
                            : null),
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

        final double mobileLeadingWidth = isCompact
            ? (showDate ? 48.0 : 38.0)
            : (showDate ? 48.0 : 40.0);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _TimeWidget(
              item: item,
              showDate: showDate,
              style: style,
              isCompact: isCompact,
              fixedWidth: mobileLeadingWidth,
            ),
            const SizedBox(width: AppSizes.p6),
            AppAvatar(
              name: avatarName,
              radius: avatarRadius,
              color: style.avatarBg,
              icon: avatarIcon,
            ),
            const SizedBox(width: AppSizes.p6),
            Expanded(
              child: _NameStatus(
                item: item,
                status: status,
                style: style,
                statusBadge: statusBadge,
                isPastScheduled: isPastScheduled,
                clinic: clinic,
                isCompact: isCompact,
                isPatientContext: isPatientContext,
              ),
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
      },
    );
  }
}
