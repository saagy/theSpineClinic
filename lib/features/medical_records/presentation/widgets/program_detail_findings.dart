import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/shared/widgets/record_section.dart';

class ProgramDetailFindings extends StatelessWidget {
  const ProgramDetailFindings({super.key, required this.program, this.onEdit});
  final PatientProgram program;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final findings = <String, String?>{
      AppStrings.examination: program.examination,
      AppStrings.imagingNotes: program.imagingNotes,
      AppStrings.exaggeratingPositions: program.exaggeratingPositions,
      AppStrings.relievingPositions: program.relievingPositions,
      AppStrings.programNotes: program.notes,
    };
    final entries = findings.entries.where((entry) => entry.value?.trim().isNotEmpty == true).toList();
    return RecordSection(
      title: AppStrings.clinicalFindingsSection,
      action: onEdit == null ? null : AppStrings.edit,
      onAction: onEdit,
      child: entries.isEmpty
          ? const RecordMessage(message: AppStrings.clinicalFindingsNotRecorded)
          : LayoutBuilder(
              builder: (context, constraints) {
                final wide =
                    constraints.maxWidth >= AppSizes.desktopBreakpoint &&
                    MediaQuery.textScalerOf(context).scale(1) <= AppSizes.formPairMaxTextScale;
                final width = wide ? (constraints.maxWidth - AppSizes.p24) / 2 : constraints.maxWidth;
                return Wrap(
                  spacing: AppSizes.p24,
                  runSpacing: AppSizes.p12,
                  children: [
                    for (final entry in entries)
                      SizedBox(
                        width: width,
                        child: RecordFact(label: entry.key, value: entry.value!.trim()),
                      ),
                  ],
                );
              },
            ),
    );
  }
}
