import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

class RecordFilterButton extends StatelessWidget {
  const RecordFilterButton({
    super.key,
    required this.onPressed,
    this.compact = false,
    this.activeFiltersCount = 0,
  });

  final VoidCallback onPressed;
  final bool compact;
  final int activeFiltersCount;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bool hasActive = activeFiltersCount > 0;

    if (compact) {
      final button = IconButton.outlined(
        tooltip: AppStrings.filterSort,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          side: BorderSide(
            color: hasActive ? cs.primary : cs.outlineVariant,
            width: AppSizes.borderWidth,
          ),
          backgroundColor: hasActive ? cs.primaryContainer.withAlpha(80) : null,
          minimumSize: const Size(AppSizes.tappableMin, AppSizes.buttonHeightSmall),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r8)),
        ),
        icon: Icon(
          LucideIcons.sliders_horizontal,
          size: AppSizes.iconSmall,
          color: hasActive ? cs.primary : cs.onSurfaceVariant,
        ),
      );

      if (!hasActive) return button;

      return Badge.count(
        count: activeFiltersCount,
        backgroundColor: cs.primary,
        textColor: cs.onPrimary,
        child: button,
      );
    }

    return Tooltip(
      message: AppStrings.filterSort,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          LucideIcons.sliders_horizontal,
          size: AppSizes.iconSmall,
          color: hasActive ? cs.primary : cs.onSurfaceVariant,
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.filtersButton,
              style: AppTextStyles.captionBold.copyWith(
                color: hasActive ? cs.primary : cs.onSurface,
              ),
            ),
            if (hasActive) ...[
              const SizedBox(width: AppSizes.p6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$activeFiltersCount',
                  style: AppTextStyles.captionBold.copyWith(
                    color: cs.onPrimary,
                    fontSize: 10.0,
                  ),
                ),
              ),
            ],
          ],
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: hasActive ? cs.primary : cs.outlineVariant,
            width: AppSizes.borderWidth,
          ),
          backgroundColor: hasActive ? cs.primaryContainer.withAlpha(80) : cs.surface,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p12, vertical: AppSizes.p8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r8)),
          minimumSize: const Size(0, AppSizes.buttonHeightSmall),
        ),
      ),
    );
  }
}
