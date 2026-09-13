import 'package:spine_clinic_app/shared/widgets/form_section.dart';

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

    return FormSection(
      title: AppStrings.programConditions,
      action: TextButton.icon(
        onPressed: () => _openPicker(context),
        icon: Icon(
          selectedConditions.isEmpty ? Icons.add : Icons.edit_outlined,
          size: AppSizes.iconSmall,
        ),
        label: Text(selectedConditions.isEmpty ? AppStrings.add : AppStrings.edit),
      ),
      child: sorted.isEmpty
          ? Text(
              AppStrings.noConditionsSelected,
              style: AppTextStyles.bodySecondary.copyWith(color: cs.onSurfaceVariant),
            )
          : Column(
              children: [
                for (final condition in sorted)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(condition.conditionName, style: AppTextStyles.bodyMedium),
                    subtitle: Text(condition.region.displayName, style: AppTextStyles.caption),
                    trailing: IconButton(
                      tooltip: AppStrings.delete,
                      icon: const Icon(Icons.close, size: AppSizes.iconSmall),
                      onPressed: () => onConditionsChanged(
                        selectedConditions.where((item) => item.id != condition.id).toList(),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
