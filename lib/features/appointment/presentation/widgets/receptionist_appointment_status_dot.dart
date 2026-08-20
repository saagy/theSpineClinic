part of 'receptionist_appointment_card.dart';

/// Colour-coded dot + coloured text — no background pill.
class _StatusDot extends StatelessWidget {
  const _StatusDot({
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
