import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/file_display_helper.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/screens/program_gallery_viewer_screen.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_document_groups.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_documents.dart';

class WorkspaceDocumentFolder extends StatelessWidget {
  const WorkspaceDocumentFolder({super.key, required this.group, required this.patientId});
  final ProgramDocumentGroup group;
  final String patientId;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = group.program?.conditions
        .map((c) => c.condition?.conditionName)
        .whereType<String>()
        .join(', ');
    final image = group.documents.where((d) => FileDisplayHelper.isImage(d.fileName)).firstOrNull;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.p12),
      child: Material(
        color: cs.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.r8),
          onTap: () => ProgramGalleryViewerScreen.open(
            context,
            documents: group.documents,
            title: name?.isNotEmpty == true ? name! : AppStrings.program,
            patientId: patientId,
            programId: group.program?.id,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Row(
              children: [
                if (image != null)
                  DocumentThumbnail(document: image)
                else
                  SizedBox.square(
                    dimension: AppSizes.documentPreviewSize,
                    child: Icon(Icons.folder_outlined, color: cs.primary, size: AppSizes.iconLarge),
                  ),
                const SizedBox(width: AppSizes.p16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name?.isNotEmpty == true ? name! : AppStrings.program,
                        style: AppTextStyles.bodyBold,
                      ),
                      const SizedBox(height: AppSizes.p6),
                      Text(AppStrings.scanCountLabel(group.count), style: AppTextStyles.caption),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.p12),
                Icon(Icons.folder_open_outlined, color: cs.primary, size: AppSizes.iconDefault),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
