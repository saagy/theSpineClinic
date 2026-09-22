part of 'due_patient_card.dart';

/// Due-patient row with actions alongside or below the identity.
class _DuePatientCompactRow extends StatelessWidget {
  const _DuePatientCompactRow({
    required this.patient,
    required this.due,
    required this.overdue,
    required this.colors,
    required this.clinic,
    required this.onCall,
    required this.onBook,
    required this.onRemindLater,
    required this.onStopFollowUp,
  });

  final Patient patient;
  final DateTime? due;
  final bool overdue;
  final ColorScheme colors;
  final ClinicColors clinic;
  final VoidCallback onCall;
  final VoidCallback onBook;
  final VoidCallback onRemindLater;
  final VoidCallback onStopFollowUp;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final actionsBelow =
            constraints.maxWidth < AppSizes.bookingActionsBelowWidth ||
            (MediaQuery.textScalerOf(context).scale(1) > 1.3 &&
                constraints.maxWidth < AppSizes.bookingEnlargedActionsBelowWidth);
        if (actionsBelow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _identity(),
              const SizedBox(height: AppSizes.p8),
              Align(alignment: Alignment.centerRight, child: _actions()),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: _identity()),
            const SizedBox(width: AppSizes.p4),
            _actions(),
          ],
        );
      },
    );
  }

  Widget _identity() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        PatientMonogramBadge(name: patient.fullName, size: AppSizes.p32),
        const SizedBox(width: AppSizes.p8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                patient.fullName,
                style: AppTextStyles.bodyBold.copyWith(color: colors.onSurface),
              ),
              const SizedBox(height: AppSizes.p2),
              Text(
                patient.phoneNumber,
                style: AppTextStyles.caption.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              if (due != null)
                Text(
                  overdue
                      ? AppStrings.overdueSince(DateFormat('MMM d').format(due!))
                      : AppStrings.dueOn(DateFormat('MMM d').format(due!)),
                  style: AppTextStyles.captionBold.copyWith(
                    color: overdue ? clinic.warning : colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actions() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
        _CompactActionButton(
          icon: Icons.call_outlined,
          tooltip: AppStrings.call,
          backgroundColor: colors.surfaceContainerHigh,
          foregroundColor: colors.primary,
          onTap: onCall,
        ),
        const SizedBox(width: AppSizes.p4),
        _CompactActionButton(
          icon: Icons.event_available_rounded,
          tooltip: AppStrings.book,
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.onPrimaryContainer,
          onTap: onBook,
        ),
        _DuePatientMenu(
          onRemindLater: onRemindLater,
          onStopFollowUp: onStopFollowUp,
          isCompact: true,
        ),
    ],
  );
}

class _CompactActionButton extends StatelessWidget {
  const _CompactActionButton({
    required this.icon,
    required this.tooltip,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r8)),
        child: InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r8)),
          child: SizedBox(
            width: AppSizes.tappableMin,
            height: AppSizes.tappableMin,
            child: Center(
              child: Icon(
                icon,
                size: AppSizes.iconDefault,
                color: foregroundColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
