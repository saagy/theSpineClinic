library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_imaging_picker.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/shared/widgets/app_text_field.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';

/// Clinical observation inputs for the program form, grouped into sections.
class ProgramClinicalInputs extends StatelessWidget {
  const ProgramClinicalInputs({
    super.key,
    required this.examinationController,
    required this.imagingNotesController,
    required this.exaggeratingPositionsController,
    required this.relievingPositionsController,
    required this.notesController,
    required this.pendingFiles,
    required this.existingDocuments,
    required this.onPendingFilesChanged,
    this.onDeleteExistingDocument,
  });

  final TextEditingController examinationController;
  final TextEditingController imagingNotesController;
  final TextEditingController exaggeratingPositionsController;
  final TextEditingController relievingPositionsController;
  final TextEditingController notesController;
  final List<PlatformFile> pendingFiles;
  final List<PatientDocument> existingDocuments;
  final ValueChanged<List<PlatformFile>> onPendingFilesChanged;
  final ValueChanged<PatientDocument>? onDeleteExistingDocument;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          title: AppStrings.clinicalFindingsSection,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                controller: examinationController,
                labelText: AppStrings.examination,
                hintText: AppStrings.examinationHint,
                maxLines: 3,
              ),
              const SizedBox(height: AppSizes.p16),
              AppTextField(
                controller: imagingNotesController,
                labelText: AppStrings.imagingNotes,
                hintText: AppStrings.imagingNotesHint,
                maxLines: 3,
              ),
              const SizedBox(height: AppSizes.p12),
              ProgramImagingPicker(
                pendingFiles: pendingFiles,
                existingDocuments: existingDocuments,
                onPendingFilesChanged: onPendingFilesChanged,
                onDeleteExistingDocument: onDeleteExistingDocument,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.p16),
        SectionCard(
          title: AppStrings.positionsSection,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                controller: exaggeratingPositionsController,
                labelText: AppStrings.exaggeratingPositions,
                hintText: AppStrings.exaggeratingPositionsHint,
                maxLines: 2,
              ),
              const SizedBox(height: AppSizes.p16),
              AppTextField(
                controller: relievingPositionsController,
                labelText: AppStrings.relievingPositions,
                hintText: AppStrings.relievingPositionsHint,
                maxLines: 2,
              ),
              const SizedBox(height: AppSizes.p16),
              AppTextField(
                controller: notesController,
                labelText: AppStrings.programNotes,
                hintText: AppStrings.programNotesHint,
                maxLines: 3,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
