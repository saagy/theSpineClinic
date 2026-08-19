/// Helper widgets for [ReceptionistTodayTab]: search field with embedded actions.
///
/// Extracted to keep the parent file under 200 lines.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// Full-width search field for the schedule tab with integrated trailing action icons.
class TodaySearchField extends StatelessWidget {
  const TodaySearchField({
    super.key,
    required this.onChanged,
    required this.onFilterPressed,
    this.isFilterActive = false,
    this.canReplace = false,
    this.onReplacePressed,
  });

  final ValueChanged<String> onChanged;
  final VoidCallback onFilterPressed;
  final bool isFilterActive;
  final bool canReplace;
  final VoidCallback? onReplacePressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p16,
        AppSizes.p4,
        AppSizes.p16,
        AppSizes.p8,
      ),
      child: TextField(
        onChanged: onChanged,
        style: AppTextStyles.body,
        decoration: InputDecoration(
          hintText: AppStrings.searchByPatientNameHint,
          hintStyle: AppTextStyles.bodySecondary,
          prefixIcon: Icon(
            Icons.search_rounded,
            color: colorScheme.primary,
            size: AppSizes.iconDefault,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onFilterPressed,
                icon: Icon(
                  Icons.filter_list_rounded,
                  color: isFilterActive
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  size: AppSizes.iconDefault,
                ),
                tooltip: AppStrings.filters,
                visualDensity: VisualDensity.compact,
              ),
              if (canReplace && onReplacePressed != null) ...[
                IconButton(
                  onPressed: onReplacePressed,
                  icon: Icon(
                    Icons.swap_horiz_rounded,
                    color: colorScheme.onSurfaceVariant,
                    size: AppSizes.iconDefault,
                  ),
                  tooltip: AppStrings.replaceDoctor,
                  visualDensity: VisualDensity.compact,
                ),
              ],
              const SizedBox(width: AppSizes.p4),
            ],
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p12,
            vertical: AppSizes.p8,
          ),
        ),
      ),
    );
  }
}
