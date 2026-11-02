import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// A consistent, keyboard-accessible radio row for every filter sheet.
class FilterSortOption extends StatelessWidget {
  const FilterSortOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    checked: selected,
    inMutuallyExclusiveGroup: true,
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      minTileHeight: AppSizes.tappableMin,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        size: AppSizes.iconDefault,
        color: selected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(label, style: AppTextStyles.bodyMedium),
      onTap: onTap,
    ),
  );
}
