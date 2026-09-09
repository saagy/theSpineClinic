import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/shared/widgets/record_section.dart';

class ProgramDetailConditions extends StatelessWidget {
  const ProgramDetailConditions({super.key, required this.program});
  final PatientProgram program;
  @override
  Widget build(BuildContext context) {
    final regions = program.affectedRegions.toList()..sort((a, b) => a.displayName.compareTo(b.displayName));
    return RecordSection(
      title: AppStrings.affectedRegions,
      trailing: Text(AppStrings.conditionsCount(program.conditions.length), style: AppTextStyles.caption),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (regions.isEmpty) const RecordMessage(message: AppStrings.noConditionsRecorded),
          for (final region in regions)
            RecordFact(
              label: region.displayName,
              value: program.conditions
                  .where((c) => c.condition?.region == region)
                  .map((c) => c.condition?.conditionName ?? AppStrings.conditionUnspecified)
                  .join('\n'),
            ),
        ],
      ),
    );
  }
}
