part of 'receptionist_grouped_appointment_card.dart';

/// Header for grouped appointment card showing time, patient name, and dual session tag.
class _GroupedCardHeader extends StatelessWidget {
  const _GroupedCardHeader({
    required this.patientName,
    required this.timeStr,
    required this.allCancelled,
    required this.trailing,
  });

  final String patientName;
  final String timeStr;
  final bool allCancelled;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clinic = ClinicColors.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    timeStr,
                    style: AppTextStyles.captionBold.copyWith(
                      color: allCancelled
                          ? clinic.textMuted
                          : theme.colorScheme.onSurface,
                      fontFeatures: AppTextStyles.number.fontFeatures,
                    ),
                  ),
                  const SizedBox(width: AppSizes.p8),
                  Expanded(
                    child: AutoSizeText(
                      patientName,
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
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.p4),
              Text(
                AppStrings.dualSession,
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
        if (trailing != null) trailing!,
      ],
    );
  }
}
