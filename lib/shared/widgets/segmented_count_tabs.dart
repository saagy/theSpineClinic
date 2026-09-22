import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

class SegmentedCountTabItem {
  const SegmentedCountTabItem({
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;
}

/// Compact, full-width list tabs with a stable underline and count.
class SegmentedCountTabs extends StatelessWidget {
  const SegmentedCountTabs({super.key, required this.items});

  final List<SegmentedCountTabItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        for (final item in items)
          Expanded(
            child: Semantics(
              button: true,
              selected: item.isActive,
              label: AppStrings.sectionCount(item.label, item.count),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: item.onTap,
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: AppSizes.tappableMin,
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.p8,
                      vertical: AppSizes.p10,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: item.isActive
                              ? colors.primary
                              : colors.outlineVariant,
                          width: item.isActive
                              ? AppSizes.borderWidthFocused
                              : AppSizes.borderWidth,
                        ),
                      ),
                    ),
                    child: MediaQuery.textScalerOf(context).scale(1) > 1.3
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.label,
                                textAlign: TextAlign.center,
                                style:
                                    (item.isActive
                                            ? AppTextStyles.bodyBold
                                            : AppTextStyles.bodyMedium)
                                        .copyWith(
                                          color: item.isActive
                                              ? colors.primary
                                              : colors.onSurfaceVariant,
                                        ),
                              ),
                              Text(
                                '${item.count}',
                                style: AppTextStyles.captionBold.copyWith(
                                  color: item.isActive
                                      ? colors.primary
                                      : colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            AppStrings.sectionCount(item.label, item.count),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                (item.isActive
                                        ? AppTextStyles.bodyBold
                                        : AppTextStyles.bodyMedium)
                                    .copyWith(
                                      color: item.isActive
                                          ? colors.primary
                                          : colors.onSurfaceVariant,
                                    ),
                          ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
