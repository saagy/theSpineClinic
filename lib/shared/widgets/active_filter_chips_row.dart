/// A collapsible row of deletable filter chips shown between the sort/filter
/// bar and the content list.
///
/// Displays a pinned "Clear All" button followed by horizontally scrollable
/// chips — each with a label and an ✕ to remove that single filter. When no
/// filters are active the entire row disappears, keeping the UI clean.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// Describes a single active filter chip.
class ActiveFilterChip {
  /// Creates an [ActiveFilterChip].
  const ActiveFilterChip({required this.label, required this.onRemove});

  /// Text displayed on the chip (e.g. "Checked In", "Dr. Smith").
  final String label;

  /// Called when the user taps the chip or its ✕ to remove this filter.
  final VoidCallback onRemove;
}

/// A horizontal row of deletable filter chips with a pinned "Clear All" action.
///
/// When [chips] is empty the widget renders [SizedBox.shrink] so the layout
/// collapses with zero height.
class ActiveFilterChipsRow extends StatelessWidget {
  /// Creates an [ActiveFilterChipsRow].
  const ActiveFilterChipsRow({
    super.key,
    required this.chips,
    required this.onClearAll,
  });

  /// The list of active filters to display.
  final List<ActiveFilterChip> chips;

  /// Called when the user taps "Clear All".
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p16,
        AppSizes.p2,
        0,
        AppSizes.p8,
      ),
      child: SizedBox(
        height: AppSizes.buttonHeightSmall,
        child: Row(
          children: [
            // ── Pinned Clear All ──
            Material(
              color: cs.errorContainer,
              borderRadius: const BorderRadius.all(
                Radius.circular(AppSizes.r24),
              ),
              child: InkWell(
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppSizes.r24),
                ),
                onTap: onClearAll,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.p12,
                    vertical: AppSizes.p6,
                  ),
                  child: Text(
                    AppStrings.clearAll,
                    style: AppTextStyles.captionBold.copyWith(
                      color: cs.onErrorContainer,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.p4),
            Container(
              width: 1,
              height: AppSizes.iconDefault,
              color: cs.outline,
            ),
            const SizedBox(width: AppSizes.p4),
            // ── Scrollable chips ──
            Expanded(
              child: Stack(
                children: [
                  ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: chips.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSizes.p8),
                    itemBuilder: (context, index) {
                      final chip = chips[index];
                      return _FilterChip(
                        label: chip.label,
                        onTap: chip.onRemove,
                      );
                    },
                  ),
                  // Right-edge fade gradient
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Container(
                        width: AppSizes.iconLarge,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                            colors: [
                              Theme.of(context).scaffoldBackgroundColor,
                              Theme.of(
                                context,
                              ).scaffoldBackgroundColor.withAlpha(0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.primaryContainer,
      borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r24)),
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r24)),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(
            left: AppSizes.p12,
            right: AppSizes.p8,
            top: AppSizes.p6,
            bottom: AppSizes.p6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.captionMedium.copyWith(
                  color: cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppSizes.p2),
              Icon(Icons.close, size: 14, color: cs.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}
