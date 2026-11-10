import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/screens/program_gallery_viewer_screen.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import 'package:spine_clinic_app/shared/widgets/record_section.dart';
import 'program_media_reel.dart';

class ProgramDetailDocuments extends ConsumerWidget {
  const ProgramDetailDocuments({super.key, required this.program, this.onEdit});
  final PatientProgram program;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = programDocumentsProvider(patientId: program.patientId, programId: program.id);
    final documents = ref.watch(provider);
    return RecordSection(
      title: AppStrings.tabDocuments,
      action: onEdit == null
          ? null
          : documents.hasValue && documents.requireValue.isEmpty
          ? AppStrings.addDocument
          : AppStrings.manage,
      onAction: onEdit,
      child: RecordAsync(
        value: documents,
        onRetry: () {
          ref.invalidate(patientDocumentsNotifierProvider(program.patientId));
          ref.invalidate(provider);
        },
        data: (docs) => docs.isEmpty
            ? const RecordMessage(message: AppStrings.noDocumentsYet)
            : ProgramMediaReel(
                documents: docs,
                showHeading: false,
                onOpenDocument: (index) => ProgramGalleryViewerScreen.open(
                  context,
                  documents: docs,
                  initialIndex: index,
                  patientId: program.patientId,
                  programId: program.id,
                ),
              ),
      ),
    );
  }
}
