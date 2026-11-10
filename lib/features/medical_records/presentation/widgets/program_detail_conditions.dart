import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/shared/widgets/record_section.dart';

class ProgramDetailConditions extends StatelessWidget {
  const ProgramDetailConditions({super.key, required this.program, this.onEdit});
  final PatientProgram program;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final regions = program.affectedRegions.toList()..sort((a, b) => a.displayName.compareTo(b.displayName));
    return RecordSection(
      title: AppStrings.affectedRegions,
      action: onEdit == null ? null : AppStrings.edit,
      onAction: onEdit,
      child: regions.isEmpty
          ? const RecordMessage(message: AppStrings.noConditionsRecorded)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.conditionsCount(program.conditions.length),
                  style: AppTextStyles.caption.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                for (final region in regions)
                  RecordFact(
                    label: region.displayName,
                    value: program.conditions
                        .where((item) => item.condition?.region == region)
                        .map((item) => item.condition?.conditionName ?? AppStrings.conditionUnspecified)
                        .join('\n'),
                  ),
              ],
            ),
    );
  }
}
