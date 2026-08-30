library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_picker_card.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_document_preview.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';

/// Form component to pick, preview, and manage imaging files (X-rays, MRI, CT).
class ProgramImagingPicker extends StatelessWidget {
  const ProgramImagingPicker({
    super.key,
    required this.pendingFiles,
    required this.existingDocuments,
    required this.onPendingFilesChanged,
    this.onDeleteExistingDocument,
  });

  final List<PlatformFile> pendingFiles;
  final List<PatientDocument> existingDocuments;
  final ValueChanged<List<PlatformFile>> onPendingFilesChanged;
  final ValueChanged<PatientDocument>? onDeleteExistingDocument;

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      allowMultiple: true,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final updated = List<PlatformFile>.from(pendingFiles);
    for (final file in result.files) {
      if (file.bytes != null && !updated.any((f) => f.name == file.name)) {
        updated.add(file);
      }
    }
    onPendingFilesChanged(updated);
  }

  void _removePending(int index) {
    final updated = List<PlatformFile>.from(pendingFiles)..removeAt(index);
    onPendingFilesChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final totalCount = pendingFiles.length + existingDocuments.length;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 20,
                    color: cs.primary,
                  ),
                  const SizedBox(width: AppSizes.p8),
                  Text(
                    AppStrings.imagingAttachments,
                    style: AppTextStyles.cardTitle.copyWith(
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
              if (totalCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.p8,
                    vertical: AppSizes.p2,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(AppSizes.r12),
                  ),
                  child: Text(
                    AppStrings.scanCountLabel(totalCount),
                    style: AppTextStyles.captionBold.copyWith(
                      color: cs.onPrimaryContainer,
                      fontSize: AppSizes.fontSizeXs,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.p12),
          if (totalCount > 0) ...[
            SizedBox(
              height: 128,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  ...existingDocuments.map(
                    (doc) => Padding(
                      padding: const EdgeInsets.only(right: AppSizes.p8),
                      child: ProgramPickerCard(
                        fileName: doc.fileName,
                        previewWidget: PatientDocumentPreview(document: doc),
                        onDelete: () => onDeleteExistingDocument?.call(doc),
                      ),
                    ),
                  ),
                  ...pendingFiles.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(right: AppSizes.p8),
                      child: ProgramPickerCard(
                        fileName: entry.value.name,
                        imageBytes: entry.value.bytes,
                        onDelete: () => _removePending(entry.key),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.p12),
          ],
          AppButton(
            labelText: AppStrings.attachImagingFiles,
            icon: Icons.add_photo_alternate_outlined,
            variant: AppButtonVariant.secondary,
            onPressed: _pickFiles,
          ),
        ],
      ),
    );
  }
}
