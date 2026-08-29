part of 'receptionist_grouped_appointment_card.dart';

/// Single sub-appointment row inside [ReceptionistGroupedAppointmentCard].
class _GroupedSubAppointmentRow extends ConsumerWidget {
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

  static const double _wideBreakpoint = 500.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final clinic = ClinicColors.of(context);
    final isCompact = ref.watch(scheduleCompactControllerProvider);
    final subAppt = item.appointment;
    final isCancelled = subAppt.status == AppointmentStatus.cancelled;
    final localTime = subAppt.scheduledAt.toLocal();
    final formattedTime = DateFormat('h:mm a').format(localTime);

    final user = ref.watch(currentUserProvider).value;
    final bool isDoctor = user?.role == UserRole.doctor;
    final canAccessAsync = isDoctor
        ? ref.watch(
            canAccessAppointmentProvider(
              appointmentId: item.appointment.id,
              patientId: item.patient.id,
            ),
          )
        : const AsyncValue.data(true);
    final bool canAccess = canAccessAsync.value ?? !isDoctor;
    final bool canInteractWithMenu = isAuthorizedStaff && canAccess;

    final bool isPastScheduled =
        subAppt.status == AppointmentStatus.scheduled &&
        DateUtils.dateOnly(localTime)
            .isBefore(DateUtils.dateOnly(DateTime.now()));

    final Color dotColor = isPastScheduled
        ? clinic.warning
        : switch (subAppt.status) {
            AppointmentStatus.scheduled => clinic.neutral,
            AppointmentStatus.checkedIn => clinic.success,
            AppointmentStatus.cancelled => theme.colorScheme.error,
          };

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= _wideBreakpoint;
        final Widget rowContent = isWide
            ? _GroupedSubAppointmentWideRow(
                item: item,
                formattedTime: formattedTime,
                dotColor: dotColor,
                isCancelled: isCancelled,
                isPastScheduled: isPastScheduled,
                isCompact: isCompact,
                canInteractWithMenu: canInteractWithMenu,
                onStatusChanged: onStatusChanged,
              )
            : _GroupedSubAppointmentMobileRow(
                item: item,
                formattedTime: formattedTime,
                dotColor: dotColor,
                isCancelled: isCancelled,
                isPastScheduled: isPastScheduled,
                isCompact: isCompact,
                canInteractWithMenu: canInteractWithMenu,
                onStatusChanged: onStatusChanged,
              );

        return GestureDetector(
          onLongPressStart: (details) {
            if (canInteractWithMenu) {
              onShowStatusMenu(subAppt, details.globalPosition);
            }
          },
          onSecondaryTapDown: (details) {
            if (canInteractWithMenu) {
              onShowStatusMenu(subAppt, details.globalPosition);
            }
          },
          child: InkWell(
            borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r8)),
            onTap: () async {
              if (!canAccess) {
                AppSnackbar.show(
                  context,
                  message: AppStrings.errorDatabasePermissionDenied,
                  variant: AppSnackbarVariant.error,
                );
                return;
              }
              await context.push(
                AppRoutes.appointmentDetail.replaceAll(
                  ':id',
                  subAppt.id,
                ),
              );
              if (context.mounted) onStatusChanged?.call();
            },
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: isCompact ? 1.0 : AppSizes.p6,
                horizontal: AppSizes.p4,
              ),
              child: rowContent,
            ),
          ),
        );
      },
    );
  }
}
