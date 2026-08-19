part of 'due_patient_card.dart';

/// Compact single-row layout for due patient booking cards.
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppAvatar(
          name: patient.fullName,
          radius: 12,
        ),
        const SizedBox(width: AppSizes.p8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AutoSizeText(
                patient.fullName,
                style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
                maxLines: 1,
                minFontSize: 10,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    flex: 2,
                    child: Text(
                      patient.phoneNumber,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 10,
                        color: colors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (due != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.p4,
                      ),
                      child: Text(
                        '•',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          color: colors.outline,
                        ),
                      ),
                    ),
                    Flexible(
                      flex: 3,
                      child: AutoSizeText(
                        overdue
                            ? AppStrings.overdueSince(
                                DateFormat('MMM d').format(due!),
                              )
                            : AppStrings.dueOn(
                                DateFormat('MMM d').format(due!),
                              ),
                        style: AppTextStyles.captionBold.copyWith(
                          fontSize: 10,
                          color: overdue
                              ? clinic.warning
                              : colors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        minFontSize: 8,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSizes.p6),
        _CompactActionButton(
          icon: Icons.call_outlined,
          tooltip: AppStrings.call,
          backgroundColor: colors.surfaceContainerHighest,
          foregroundColor: colors.primary,
          onTap: onCall,
        ),
        const SizedBox(width: AppSizes.p6),
        _CompactActionButton(
          icon: Icons.event_available_rounded,
          tooltip: AppStrings.book,
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.onPrimaryContainer,
          onTap: onBook,
        ),
        const SizedBox(width: AppSizes.p2),
        _DuePatientMenu(
          onRemindLater: onRemindLater,
          onStopFollowUp: onStopFollowUp,
          isCompact: true,
        ),
      ],
    );
  }
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
            width: 30,
            height: 30,
            child: Center(
              child: Icon(
                icon,
                size: 15,
                color: foregroundColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
