part of 'receptionist_grouped_appointment_card.dart';

/// Colour-coded dot + coloured text with smooth morphing and rolling ticker label for sub-rows.
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
    final double iconSize = isCompact ? 11.5 : 13.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              ),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: icon == null
              ? AnimatedContainer(
                  key: const ValueKey<String>('grouped_status_dot'),
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  width: isCompact ? 5 : AppSizes.p6,
                  height: isCompact ? 5 : AppSizes.p6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                )
              : Icon(
                  icon,
                  key: ValueKey<IconData>(icon!),
                  color: color,
                  size: iconSize,
                ),
        ),
        const SizedBox(width: AppSizes.p4),
        Flexible(
          child: RollingTickerText(
            text: label,
            duration: const Duration(milliseconds: 240),
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontSize: isCompact ? 10 : 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
