/// Mobile-native segmented control with count badges.
///
/// Replaces Material 3 [SegmentedButton] on narrow viewports where two
/// stacked segments read as disconnected cards. Renders a full-bleed
/// horizontal row of pill-shaped chips, each carrying an icon, a label,
/// and a count badge.
///
/// All styling respects the active [Theme] — primary/onPrimary for the
/// active chip, surfaceContainerHigh/onSurfaceVariant for inactive.
/// Touch-only feedback via [InkWell]; no hover affordances.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';

/// One row item in a [SegmentedCountTabs] row.
class SegmentedCountTabItem {
  /// Creates a [SegmentedCountTabItem].
  const SegmentedCountTabItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  /// Glyph rendered left of the label.
  final IconData icon;

  /// Text label (e.g. "Due patients").
  final String label;

  /// Numeric count displayed in a trailing badge.
  final int count;

  /// Whether this item is the active selection.
  final bool isActive;

  /// Triggered on tap.
  final VoidCallback onTap;
}

/// A full-width row of count-bearing pill tabs backed by [Theme.of].
class SegmentedCountTabs extends StatelessWidget {
  /// Creates a [SegmentedCountTabs].
  const SegmentedCountTabs({super.key, required this.items});

  /// Items rendered left-to-right. Provide 2 for a binary toggle.
  final List<SegmentedCountTabItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p12,
        vertical: AppSizes.p8,
      ),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSizes.p8),
            Expanded(
              child: _SegmentedCountTab(item: items[i], colors: cs),
            ),
          ],
        ],
      ),
    );
  }
}

class _SegmentedCountTab extends StatelessWidget {
  const _SegmentedCountTab({required this.item, required this.colors});

  final SegmentedCountTabItem item;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final Color background = item.isActive
        ? colors.primary
        : colors.surfaceContainerHigh;
    final Color foreground = item.isActive
        ? colors.onPrimary
        : colors.onSurfaceVariant;
    final Color badgeBackground = item.isActive
        ? colors.onPrimary.withAlpha(28)
        : colors.outline.withAlpha(28);
    final Color badgeForeground = item.isActive
        ? colors.onPrimary
        : colors.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: item.isActive,
      label: '${item.label} (${item.count})',
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r999)),
          side: BorderSide(
            color: item.isActive ? colors.primary : colors.outline,
            width: AppSizes.borderWidth,
          ),
        ),
        child: InkWell(
          onTap: item.onTap,
          borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r999)),
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSizes.tappableMin),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.p10,
              vertical: AppSizes.p8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, size: AppSizes.iconSmall, color: foreground),
                const SizedBox(width: AppSizes.p4),
                Flexible(
                  child: Text(
                    item.label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSizes.p4),
                Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.p6,
                    vertical: AppSizes.p2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBackground,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(AppSizes.r999),
                    ),
                  ),
                  child: Text(
                    '${item.count}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: badgeForeground,
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
