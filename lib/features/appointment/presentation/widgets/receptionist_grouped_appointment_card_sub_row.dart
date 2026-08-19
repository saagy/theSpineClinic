part of 'receptionist_grouped_appointment_card.dart';

/// Single sub-appointment row inside [ReceptionistGroupedAppointmentCard].
class _GroupedSubAppointmentRow extends StatelessWidget {
  const _GroupedSubAppointmentRow({
    required this.item,
    required this.isAuthorizedStaff,
    required this.onStatusChanged,
    required this.onShowStatusMenu,
  });

  final AppointmentWithPatient item;
  final bool isAuthorizedStaff;
  final VoidCallback? onStatusChanged;
  final void Function(Appointment appointment, Offset globalPosition)
      onShowStatusMenu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clinic = ClinicColors.of(context);
    final subAppt = item.appointment;
    final isCancelled = subAppt.status == AppointmentStatus.cancelled;
    final localTime = subAppt.scheduledAt.toLocal();
    final formattedTime = DateFormat('h:mm a').format(localTime);

    final bool isPastScheduled =
        subAppt.status == AppointmentStatus.scheduled &&
        DateUtils.dateOnly(localTime).isBefore(DateUtils.dateOnly(DateTime.now()));

    final Color dotColor = isPastScheduled
        ? clinic.warning
        : switch (subAppt.status) {
            AppointmentStatus.scheduled => theme.colorScheme.primary,
            AppointmentStatus.checkedIn => clinic.success,
            AppointmentStatus.cancelled => theme.colorScheme.error,
          };

    return GestureDetector(
      onLongPressStart: (details) {
        if (isAuthorizedStaff) {
          onShowStatusMenu(subAppt, details.globalPosition);
        }
      },
      onSecondaryTapDown: (details) {
        if (isAuthorizedStaff) {
          onShowStatusMenu(subAppt, details.globalPosition);
        }
      },
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r8)),
        onTap: () async {
          await context.push(
            AppRoutes.appointmentDetail.replaceAll(
              ':id',
              subAppt.id,
            ),
          );
          if (context.mounted) onStatusChanged?.call();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSizes.p6,
            horizontal: AppSizes.p4,
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSizes.p8),
              Text(
                formattedTime,
                style: AppTextStyles.captionBold.copyWith(
                  color: isCancelled
                      ? clinic.textMuted
                      : theme.colorScheme.onSurface,
                  decoration: isCancelled ? TextDecoration.lineThrough : null,
                ),
              ),
              const SizedBox(width: AppSizes.p12),
              Expanded(
                child: Text(
                  subAppt.type.displayLabel,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isCancelled
                        ? clinic.textMuted
                        : theme.colorScheme.onSurface,
                    decoration: isCancelled ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AppointmentActionsTrailing(
                appointment: subAppt,
                onStatusChanged: onStatusChanged,
                showBadge: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
