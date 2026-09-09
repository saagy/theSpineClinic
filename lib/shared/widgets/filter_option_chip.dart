import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// The compact rectangular option used by the appointment filter sheet.
class FilterOptionChip extends StatelessWidget {
  const FilterOptionChip({super.key, required this.label, required this.isSelected, required this.onTap});
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.r8),
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSizes.tappableMin),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p12, vertical: AppSizes.p8),
        decoration: BoxDecoration(
          color: isSelected ? cs.primaryContainer : cs.surfaceContainerHighest.withAlpha(120),
          borderRadius: BorderRadius.circular(AppSizes.r8),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant.withAlpha(100),
            width: AppSizes.borderWidth,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.captionBold.copyWith(color: isSelected ? cs.onPrimaryContainer : cs.onSurface),
        ),
      ),
    );
  }
}
