part of 'due_patient_card.dart';

enum DuePatientMenuAction { remindLater, stopFollowUp }

class _DuePatientMenu extends StatelessWidget {
  const _DuePatientMenu({
    required this.onRemindLater,
    required this.onStopFollowUp,
    required this.isCompact,
  });

  final VoidCallback onRemindLater;
  final VoidCallback onStopFollowUp;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return PopupMenuButton<DuePatientMenuAction>(
      icon: Icon(
        Icons.more_horiz_rounded,
        color: colors.onSurfaceVariant,
        size: isCompact ? AppSizes.iconSmall : AppSizes.iconDefault,
      ),
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(
        minWidth: isCompact ? 28 : 36,
        minHeight: isCompact ? 28 : 36,
      ),
      splashRadius: isCompact ? AppSizes.iconSmall : AppSizes.iconDefault,
      color: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.r12)),
      ),
      elevation: 2,
      position: PopupMenuPosition.under,
      onSelected: (action) => switch (action) {
        DuePatientMenuAction.remindLater => onRemindLater(),
        DuePatientMenuAction.stopFollowUp => onStopFollowUp(),
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: DuePatientMenuAction.remindLater,
          height: AppSizes.buttonHeightSmall,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_outlined,
                color: colors.primary,
                size: AppSizes.iconSmall,
              ),
              const SizedBox(width: AppSizes.p8),
              Text(
                AppStrings.remindLater,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: DuePatientMenuAction.stopFollowUp,
          height: AppSizes.buttonHeightSmall,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.block_outlined,
                color: colors.error,
                size: AppSizes.iconSmall,
              ),
              const SizedBox(width: AppSizes.p8),
              Text(
                AppStrings.stopFollowUp,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colors.error,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
