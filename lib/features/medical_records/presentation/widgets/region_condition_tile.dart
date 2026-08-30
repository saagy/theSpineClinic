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

    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(AppSizes.r12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSizes.p4),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p16,
          vertical: AppSizes.p12,
        ),
        decoration: BoxDecoration(
          color: isSelected ? cs.primaryContainer.withAlpha(80) : cs.surface,
          borderRadius: BorderRadius.circular(AppSizes.r12),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    condition.conditionName,
                    style: AppTextStyles.body.copyWith(
                      color: isSelected ? cs.onSurface : cs.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: AppSizes.p2),
                  Text(
                    condition.region.displayName,
                    style: AppTextStyles.caption.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.p12),
            Checkbox(
              value: isSelected,
              activeColor: cs.primary,
              onChanged: (_) => onToggle(),
            ),
          ],
        ),
      ),
    );
  }
}
