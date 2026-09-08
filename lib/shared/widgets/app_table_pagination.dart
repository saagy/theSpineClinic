import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// Reusable desktop footer pagination bar for data tables and wide lists.
///
/// Displays records range (e.g. "Showing 1 to 30 of 142 appointments")
/// and accessible previous/next navigation buttons.
///
/// Rule 1 — under 200 lines.
/// Rule 7 — AppStrings constants.
/// Rule 8 — AppSizes tokens.
/// Rule 15 — Theme-driven tokens.
class AppTablePagination extends StatelessWidget {
  const AppTablePagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.pageSize,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPrevious,
    required this.onNext,
    this.entityLabel = AppStrings.paginationAppointments,
  });

  final int currentPage;
  final int totalPages;
  final int? totalCount;
  final int pageSize;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final String entityLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final int startRecord =
        totalCount == 0 ? 0 : (currentPage - 1) * pageSize + 1;
    final int endRecord = totalCount == null
        ? currentPage * pageSize
        : (currentPage * pageSize).clamp(0, totalCount!);
    final String label = totalCount != null
        ? '${AppStrings.paginationShowing} $startRecord ${AppStrings.paginationTo} $endRecord ${AppStrings.paginationOf} $totalCount $entityLabel'
        : '${AppStrings.paginationShowing} $startRecord ${AppStrings.paginationTo} $endRecord $entityLabel';

    return Container(
      height: AppSizes.paginationBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(
            color: cs.outlineVariant.withAlpha(140),
            width: AppSizes.borderWidth,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: cs.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSizes.p12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${AppStrings.paginationPage} $currentPage ${AppStrings.paginationOf} $totalPages',
                style: AppTextStyles.caption.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: AppSizes.p8),
              _PageNavButton(
                icon: LucideIcons.chevron_left,
                label: AppStrings.paginationPrevious,
                enabled: hasPrevious,
                onPressed: onPrevious,
              ),
              const SizedBox(width: AppSizes.p8),
              _PageNavButton(
                icon: LucideIcons.chevron_right,
                label: AppStrings.paginationNext,
                enabled: hasNext,
                onPressed: onNext,
                isTrailingIcon: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PageNavButton extends StatelessWidget {
  const _PageNavButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
    this.isTrailingIcon = false,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;
  final bool isTrailingIcon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Color textColor =
        enabled ? cs.onSurface : cs.onSurfaceVariant.withAlpha(120);

    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: textColor,
        disabledForegroundColor: cs.onSurfaceVariant.withAlpha(100),
        side: BorderSide(
          color: enabled ? cs.outlineVariant : cs.outlineVariant.withAlpha(60),
          width: AppSizes.borderWidth,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p12,
          vertical: AppSizes.p8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.r6),
        ),
        minimumSize: const Size(0, AppSizes.buttonHeightSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isTrailingIcon) ...[
            Icon(icon, size: AppSizes.iconSmall - 2),
            const SizedBox(width: AppSizes.p4),
          ],
          Text(
            label,
            style: AppTextStyles.captionBold.copyWith(color: textColor),
          ),
          if (isTrailingIcon) ...[
            const SizedBox(width: AppSizes.p4),
            Icon(icon, size: AppSizes.iconSmall - 2),
          ],
        ],
      ),
    );
  }
}
