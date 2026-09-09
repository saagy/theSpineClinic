import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/screens/program_gallery_viewer_screen.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_media_reel.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import 'package:spine_clinic_app/shared/widgets/record_section.dart';

class ProgramDetailFindings extends ConsumerWidget {
  const ProgramDetailFindings({super.key, required this.program});
  final PatientProgram program;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = programDocumentsProvider(patientId: program.patientId, programId: program.id);
    final findings = <String, String?>{
      AppStrings.examination: program.examination,
      AppStrings.imagingNotes: program.imagingNotes,
      AppStrings.exaggeratingPositions: program.exaggeratingPositions,
      AppStrings.relievingPositions: program.relievingPositions,
      AppStrings.programNotes: program.notes,
    };
    return RecordSection(
      title: AppStrings.clinicalFindingsSection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final entry in findings.entries)
            if (entry.value?.trim().isNotEmpty == true)
              RecordFact(label: entry.key, value: entry.value!.trim()),
          if (findings.values.every((value) => value?.trim().isNotEmpty != true))
            const RecordMessage(message: AppStrings.clinicalFindingsNotRecorded),
          RecordAsync(
            value: ref.watch(provider),
            onRetry: () => ref.invalidate(provider),
            data: (docs) => docs.isEmpty
                ? const SizedBox.shrink()
                : ProgramMediaReel(
                    documents: docs,
                    onOpenDocument: (index) => ProgramGalleryViewerScreen.open(
                      context,
                      documents: docs,
                      initialIndex: index,
                      patientId: program.patientId,
                      programId: program.id,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
