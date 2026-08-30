library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/medical_records/domain/condition_catalog.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/condition_picker_sheet.dart';

/// Interactive card allowing users to view and select catalog conditions for a program.
class ProgramConditionSelector extends StatelessWidget {
  const ProgramConditionSelector({
    super.key,
    required this.selectedConditions,
    required this.onConditionsChanged,
  });

  final List<ConditionCatalog> selectedConditions;
  final ValueChanged<List<ConditionCatalog>> onConditionsChanged;

  Future<void> _openPicker(BuildContext context) async {
    final result = await ConditionPickerSheet.show(
      context,
      initialSelectedIds: selectedConditions.map((c) => c.id).toSet(),
    );
    if (result != null) {
      onConditionsChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sorted = List<ConditionCatalog>.from(selectedConditions)
      ..sort((a, b) => a.region.displayName.compareTo(b.region.displayName));

    return Container(
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSizes.r16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.personal_injury_rounded,
                size: AppSizes.iconDefault,
                color: cs.primary,
              ),
              const SizedBox(width: AppSizes.p8),
              Expanded(
                child: Text(
                  AppStrings.selectInjuries,
                  style: AppTextStyles.cardTitle.copyWith(color: cs.onSurface),
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(
                  selectedConditions.isEmpty
                      ? AppStrings.add
                      : AppStrings.edit,
                ),
                onPressed: () => _openPicker(context),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p8),
          if (sorted.isEmpty)
            Text(
              AppStrings.noConditionsSelected,
              style: AppTextStyles.bodySecondary.copyWith(
                color: cs.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: AppSizes.p8,
              runSpacing: AppSizes.p8,
              children: sorted.map((c) {
                return Chip(
                  backgroundColor: cs.primaryContainer,
                  deleteIcon: Icon(
                    Icons.close,
                    size: 16,
                    color: cs.onPrimaryContainer,
                  ),
                  onDeleted: () {
                    final updated = List<ConditionCatalog>.from(
                      selectedConditions,
                    )..removeWhere((item) => item.id == c.id);
                    onConditionsChanged(updated);
                  },
                  label: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        c.conditionName,
                        style: AppTextStyles.captionBold.copyWith(
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        c.region.displayName,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          color: cs.onPrimaryContainer.withAlpha(180),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
