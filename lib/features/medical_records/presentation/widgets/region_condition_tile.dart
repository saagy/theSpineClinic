library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/medical_records/domain/condition_catalog.dart';

/// Single selectable condition row tile with checkbox.
class RegionConditionTile extends StatelessWidget {
  const RegionConditionTile({
    super.key,
    required this.condition,
    required this.isSelected,
    required this.onToggle,
  });

  final ConditionCatalog condition;
  final bool isSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return CheckboxListTile(
      value: isSelected,
      onChanged: (_) => onToggle(),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.p12, vertical: AppSizes.p4),
      shape: Border(bottom: BorderSide(color: cs.outlineVariant)),
      selected: isSelected,
      title: Text(condition.conditionName, style: AppTextStyles.body.copyWith(color: cs.onSurface)),
      subtitle: Text(
        condition.region.displayName,
        style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}
