import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/utils/file_display_helper.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_programs_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_document_actions.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_upload_button.dart';
import 'package:spine_clinic_app/shared/widgets/record_section.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_document_preview.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_document_groups.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_document_folder.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_tab_header.dart';

class WorkspaceDocuments extends ConsumerWidget {
  const WorkspaceDocuments({super.key, required this.patientId, this.preview = false, this.onViewAll});
  final String patientId;
  final bool preview;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = patientDocumentGroupsProvider(patientId);
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WorkspaceTabHeader(
          title: AppStrings.tabDocuments,
          trailing: preview && onViewAll != null
              ? TextButton(onPressed: onViewAll, child: const Text(AppStrings.viewAll))
              : (!preview
                  ? LayoutBuilder(
                      builder: (context, constraints) => WorkspaceUploadButton(
                        patientId: patientId,
                        iconOnly: constraints.maxWidth < 480,
                      ),
                    )
                  : null),
        ),
        const SizedBox(height: AppSizes.p14),
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppSizes.r12),
            border: Border.all(color: cs.outlineVariant.withAlpha(80)),
          ),
          child: RecordAsync(
            value: ref.watch(provider),
            onRetry: () => ref.invalidate(provider),
            data: (groups) {
              if (groups.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(AppSizes.p24),
                  child: RecordMessage(message: AppStrings.noDocumentsYet),
                );
              }
              final folders = preview ? groups.folders.take(3) : groups.folders;
              final standalone = (preview ? groups.standalone.take(3) : groups.standalone).toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final folder in folders) WorkspaceDocumentFolder(group: folder, patientId: patientId),
                  for (int i = 0; i < standalone.length; i++) ...[
                    WorkspaceDocumentRow(document: standalone[i], showActions: !preview),
                    if (i < standalone.length - 1) const Divider(height: AppSizes.borderWidth),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class WorkspaceDocumentRow extends ConsumerWidget {
  const WorkspaceDocumentRow({super.key, required this.document, this.showActions = true});
  final PatientDocument document;
  final bool showActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final programs = ref.watch(patientProgramsProvider(document.patientId)).value;
    String? programName;
    for (final program in programs ?? []) {
      if (program.id == document.programId) {
        programName = program.conditions.map((p) => p.condition?.conditionName).whereType<String>().join(', ');
      }
    }
    final name = FileDisplayHelper.sanitizeFileName(document.fileName);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(
          AppRoutes.patientDocumentViewerLocation(patientId: document.patientId, documentId: document.id),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p14),
          child: Row(
            children: [
              DocumentThumbnail(document: document),
              const SizedBox(width: AppSizes.p12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.bodyMedium.copyWith(color: colors.onSurface)),
                    const SizedBox(height: AppSizes.p4),
                    Text(
                      Formatters.formatDateMedium(document.uploadedAt),
                      style: AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                    ),
                    if (document.programId != null)
                      Text(
                        programName?.isNotEmpty == true ? programName! : AppStrings.rehabilitationProgram,
                        style: AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              if (showActions) PatientDocumentActions(document: document),
            ],
          ),
        ),
      ),
    );
  }
}

class DocumentThumbnail extends StatelessWidget {
  const DocumentThumbnail({super.key, required this.document});
  final PatientDocument document;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: AppSizes.documentPreviewSize,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.r8),
      child: PatientDocumentPreview(document: document),
    ),
  );
}
