library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_type.dart';

/// Modern, compact horizontal rail and wrap selector for treatment modalities.
class ModalityChipSelector extends StatelessWidget {
  const ModalityChipSelector({
    super.key,
    required this.selectedModalities,
    required this.onToggle,
  });

  final Set<ModalityType> selectedModalities;
  final ValueChanged<ModalityType> onToggle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 540;

        if (isDesktop) {
          return Wrap(
            spacing: AppSizes.p8,
            runSpacing: AppSizes.p8,
            children: ModalityType.values.map((type) {
              return _ModalityPill(
                type: type,
                isSelected: selectedModalities.contains(type),
                onTap: () => onToggle(type),
              );
            }).toList(),
          );
        }

        return SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: ModalityType.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSizes.p8),
            itemBuilder: (context, index) {
              final type = ModalityType.values[index];
              return _ModalityPill(
                type: type,
                isSelected: selectedModalities.contains(type),
                onTap: () => onToggle(type),
              );
            },
          ),
        );
      },
    );
  }
}

class _ModalityPill extends StatelessWidget {
  const _ModalityPill({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  final ModalityType type;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected ? cs.primaryContainer.withAlpha(50) : cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSizes.r999),
        border: Border.all(
          color: isSelected ? cs.primary : cs.outlineVariant.withAlpha(160),
          width: isSelected ? 1.5 : 1.0,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: cs.primary.withAlpha(25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.r999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p12, vertical: AppSizes.p8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? cs.primary : cs.surfaceContainerHighest.withAlpha(140),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    type.icon,
                    size: 14,
                    color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: AppSizes.p8),
                Text(
                  type.displayLabel,
                  maxLines: 1,
                  softWrap: false,
                  style: AppTextStyles.captionBold.copyWith(
                    color: isSelected ? cs.primary : cs.onSurface,
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
