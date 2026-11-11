import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';

/// One event in an invoice's activity: a marker icon, what happened, who and
/// when, optional detail lines, the money that moved, and its actions.
class InvoiceTimelineRow extends StatelessWidget {
  const InvoiceTimelineRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.details = const [],
    this.tag,
    this.amount,
    this.amountNote,
    this.voided = false,
    this.menu,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> details;

  /// Short state beside the title, such as Voided or Corrected.
  final String? tag;
  final String? amount;
  final String? amountNote;

  /// Voided documents stay readable but muted, with the amount struck out.
  final bool voided;
  final Widget? menu;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final Color strong = voided ? colors.onSurfaceVariant : colors.onSurface;
    final muted = AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant);
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: AppSizes.p16,
        end: menu == null ? AppSizes.p16 : AppSizes.p4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: AppSizes.p12),
            width: AppSizes.invoiceTimelineMarker,
            height: AppSizes.invoiceTimelineMarker,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Icon(icon, size: AppSizes.iconSmall, color: colors.onSurfaceVariant),
          ),
          const SizedBox(width: AppSizes.p12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.p12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSizes.p8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(title, style: AppTextStyles.bodyBold.copyWith(color: strong)),
                      if (tag != null)
                        Text(tag!, style: AppTextStyles.captionBold.copyWith(color: colors.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: AppSizes.p2),
                  Text(subtitle, style: muted),
                  for (final detail in details)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSizes.p2),
                      child: Text(detail, style: muted),
                    ),
                ],
              ),
            ),
          ),
          if (amount != null) ...[
            const SizedBox(width: AppSizes.p12),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.p12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amount!,
                    style: AppTextStyles.number.copyWith(
                      color: strong,
                      fontWeight: FontWeight.w600,
                      decoration: voided ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (amountNote != null) Text(amountNote!, style: muted),
                ],
              ),
            ),
          ],
          // Sits level with the title line rather than the middle of the row.
          if (menu != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSizes.p2),
              child: menu,
            ),
        ],
      ),
    );
  }
}
