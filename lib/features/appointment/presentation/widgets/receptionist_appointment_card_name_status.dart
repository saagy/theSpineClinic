part of 'receptionist_appointment_card.dart';

/// Name line + session type + status dot row.
class _NameStatus extends StatelessWidget {
  const _NameStatus({
    required this.item,
    required this.status,
    required this.style,
    required this.statusBadge,
    required this.isPastScheduled,
    required this.clinic,
    required this.isCompact,
    required this.isPatientContext,
  });

  final AppointmentWithPatient item;
  final AppointmentStatus status;
  final AppointmentStatusStyle style;
  final AppointmentBadgeColors statusBadge;
  final bool isPastScheduled;
  final ClinicColors clinic;
  final bool isCompact;
  final bool isPatientContext;

  @override
  Widget build(BuildContext context) {
    final String primaryTitle = isPatientContext
        ? (item.doctorName != null && item.doctorName!.trim().isNotEmpty
            ? (item.doctorName!.toLowerCase().startsWith('dr')
                ? item.doctorName!
                : 'Dr. ${item.doctorName}')
            : AppStrings.noDoctorsAssigned)
        : item.patient.fullName;
    final String secondaryText = item.appointment.type.displayLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AutoSizeText(
          primaryTitle,
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                secondaryText,
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
