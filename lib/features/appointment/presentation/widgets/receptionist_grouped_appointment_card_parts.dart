part of 'receptionist_grouped_appointment_card.dart';

/// Patient header row inside [ReceptionistGroupedAppointmentCard].
class _GroupedCardHeader extends StatelessWidget {
  const _GroupedCardHeader({
    required this.patient,
    required this.timeStr,
    required this.allCancelled,
    required this.isCompact,
    required this.isAuthorizedStaff,
    required this.trailingMenu,
  });

  final Patient patient;
  final String timeStr;
  final bool allCancelled;
  final bool isCompact;
  final bool isAuthorizedStaff;
  final Widget? trailingMenu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clinic = ClinicColors.of(context);

    if (isCompact) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppAvatar(
            name: patient.fullName,
            radius: 11.0,
            color: allCancelled ? clinic.textMuted : null,
          ),
          const SizedBox(width: AppSizes.p8),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: AutoSizeText(
                    patient.fullName,
                    style: AppTextStyles.bodyBold.copyWith(
                      color: allCancelled
                          ? clinic.textMuted
                          : theme.colorScheme.onSurface,
                      decoration:
                          allCancelled ? TextDecoration.lineThrough : null,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSizes.p6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.p6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withAlpha(120),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(AppSizes.r8),
                    ),
                  ),
                  child: Text(
                    AppStrings.dualSession,
                    style: AppTextStyles.caption.copyWith(
                      color: theme.colorScheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isAuthorizedStaff && trailingMenu != null) trailingMenu!,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppAvatar(
          name: patient.fullName,
          radius: AppSizes.avatarSmall / 2,
          color: allCancelled ? clinic.textMuted : null,
        ),
        const SizedBox(width: AppSizes.p12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AutoSizeText(
                patient.fullName,
                style: AppTextStyles.bodyBold.copyWith(
                  color: allCancelled
                      ? clinic.textMuted
                      : theme.colorScheme.onSurface,
                  decoration:
                      allCancelled ? TextDecoration.lineThrough : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSizes.p2),
              Text(
                '$timeStr • ${AppStrings.dualSession}',
                style: AppTextStyles.caption.copyWith(
                  color: allCancelled
                      ? clinic.textMuted
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (isAuthorizedStaff && trailingMenu != null) trailingMenu!,
      ],
    );
  }
}

/// Colour-coded dot + coloured text for sub-rows.
class _GroupedStatusDot extends StatelessWidget {
  const _GroupedStatusDot({
    required this.color,
    required this.label,
    this.icon,
    this.isCompact = false,
  });

  final Color color;
  final String label;
  final IconData? icon;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon == null)
          Container(
            width: isCompact ? 5 : AppSizes.p6,
            height: isCompact ? 5 : AppSizes.p6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          )
        else
          Icon(
            icon,
            color: color,
            size: isCompact ? 13 : AppSizes.iconSmall,
          ),
        const SizedBox(width: AppSizes.p4),
        Flexible(
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontSize: isCompact ? 10 : 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
