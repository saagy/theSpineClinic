/// A reusable row with sort and filter action buttons.
///
/// Displays a sort button (with current sort label) on the left and a filter
/// button (with optional count badge) on the right. Used by every list screen
/// that offers sort + filter controls.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// A row with sort (left) and filter (right) action buttons.
class SortFilterBar extends StatelessWidget {
  /// Creates a [SortFilterBar].
  const SortFilterBar({
    super.key,
    required this.sortLabel,
    required this.onSortTap,
    this.activeFilterCount = 0,
    required this.onFilterTap,
  });

  /// Label shown next to the sort icon (e.g. "Sort: Name A→Z").
  final String sortLabel;

  /// Called when the sort button is tapped.
  final VoidCallback onSortTap;

  /// Number of currently active filters. When > 0, shows "Filters (N)" badge.
  final int activeFilterCount;

  /// Called when the filter button is tapped.
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    final String filterLabel = activeFilterCount > 0
        ? 'Filters ($activeFilterCount)'
        : 'Filters';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p16,
        AppSizes.p4,
        AppSizes.p16,
        AppSizes.p8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Sort button ──
          InkWell(
            onTap: onSortTap,
            borderRadius:
                const BorderRadius.all(Radius.circular(AppSizes.r8)),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.p8,
                vertical: AppSizes.p6,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.swap_vert_rounded,
                    color: AppColors.primary,
                    size: AppSizes.iconDefault,
                  ),
                  const SizedBox(width: AppSizes.p4),
                  Text(
                    sortLabel,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Filter button ──
          InkWell(
            onTap: onFilterTap,
            borderRadius:
                const BorderRadius.all(Radius.circular(AppSizes.r8)),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.p8,
                vertical: AppSizes.p6,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    color: AppColors.textSecondary,
                    size: AppSizes.iconDefault,
                  ),
                  const SizedBox(width: AppSizes.p4),
                  Text(
                    filterLabel,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: activeFilterCount > 0
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: activeFilterCount > 0
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
