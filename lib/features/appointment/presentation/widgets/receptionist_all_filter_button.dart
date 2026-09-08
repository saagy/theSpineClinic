import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// Filter button with active-filter count badge for the "All" appointments tab.
///
/// Rule 1 — under 200 lines.
/// Rule 7 — AppStrings constants.
/// Rule 8 — AppSizes tokens.
/// Rule 15 — Theme-driven tokens.
class ReceptionistAllFilterButton extends StatelessWidget {
  const ReceptionistAllFilterButton({
    super.key,
    required this.activeFiltersCount,
    required this.onTap,
  });

  final int activeFiltersCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bool hasActive = activeFiltersCount > 0;

    return OutlinedButton.icon(
      onPressed: onTap,
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
              padding: const EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 1,
              ),
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
        backgroundColor: hasActive
            ? cs.primaryContainer.withAlpha(80)
            : cs.surface,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p12,
          vertical: AppSizes.p10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.r8),
        ),
        minimumSize: const Size(0, AppSizes.tappableMin),
      ),
    );
  }
}
