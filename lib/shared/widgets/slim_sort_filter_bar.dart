/// Slim sort/filter/count row — single compact line replacing
/// SortFilterBar + count label.
///
/// Layout: [sort icon + label] [filter icon + count] --- [total count]
/// Filter chips are rendered by the caller conditionally below.
///
/// Rule 15/16 — colours via Theme.of(context).colorScheme.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

class SlimSortFilterBar extends StatelessWidget {
  const SlimSortFilterBar({
    super.key,
    required this.sortLabel,
    required this.onSortTap,
    required this.onFilterTap,
    this.activeFilterCount = 0,
    this.totalCount,
  });

  final String sortLabel;
  final VoidCallback onSortTap;
  final VoidCallback onFilterTap;
  final int activeFilterCount;
  final int? totalCount;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bool hasFilters = activeFilterCount > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.p16, AppSizes.p4, AppSizes.p16, AppSizes.p4),
      child: Row(
        children: [
          _SlimButton(
            icon: Icons.sort_rounded,
            label: sortLabel,
            onTap: onSortTap,
            color: cs.primary,
          ),
          const SizedBox(width: AppSizes.p4),
          _SlimButton(
            icon: Icons.tune_rounded,
            label: hasFilters ? '($activeFilterCount)' : null,
            onTap: onFilterTap,
            color: hasFilters ? cs.primary : cs.onSurfaceVariant,
          ),
          if (totalCount != null) ...[
            const Spacer(),
            Text(
              '$totalCount',
              style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _SlimButton extends StatelessWidget {
  const _SlimButton({
    required this.icon,
    required this.onTap,
    this.color,
    this.label,
  });
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.r8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p8, vertical: AppSizes.p6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSizes.iconDefault, color: color ?? cs.onSurfaceVariant),
            if (label != null) ...[
              const SizedBox(width: AppSizes.p4),
              Text(
                label!,
                style: AppTextStyles.captionMedium.copyWith(color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
