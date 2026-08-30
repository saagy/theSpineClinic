library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';

/// Card displaying the clinical examination, imaging findings, scans, and position findings.
class ProgramDetailFindings extends ConsumerWidget {
  const ProgramDetailFindings({super.key, required this.program});

  final PatientProgram program;

  Widget _buildFindingSection({
    required BuildContext context,
    required String title,
    required String? content,
    required IconData icon,
  }) {
    if (content == null || content.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.p12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: cs.primary),
              const SizedBox(width: AppSizes.p6),
              Text(
                title,
                style: AppTextStyles.captionBold.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p4),
          Padding(
            padding: const EdgeInsets.only(left: AppSizes.p24),
            child: Text(
              content.trim(),
              style: AppTextStyles.body.copyWith(color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagingAttachments(
    BuildContext context,
    List<PatientDocument> docs,
  ) {
    if (docs.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.p12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_library_outlined, size: 16, color: cs.primary),
              const SizedBox(width: AppSizes.p6),
              Text(
                AppStrings.imagingAttachments,
                style: AppTextStyles.captionBold.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p8),
          Wrap(
            spacing: AppSizes.p8,
            runSpacing: AppSizes.p8,
            children: docs.map((doc) {
              final isPdf = doc.fileName.toLowerCase().endsWith('.pdf');
              return InkWell(
                onTap: () {
                  final location = AppRoutes.patientDocumentViewerLocation(
                    patientId: program.patientId,
                    documentId: doc.id,
                  );
                  context.push(location);
                },
                borderRadius: BorderRadius.circular(AppSizes.r12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.p10,
                    vertical: AppSizes.p6,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(AppSizes.r12),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPdf
                            ? Icons.picture_as_pdf_rounded
                            : Icons.image_rounded,
                        size: 18,
                        color: isPdf ? cs.error : cs.primary,
                      ),
                      const SizedBox(width: AppSizes.p6),
                      Text(
                        doc.fileName,
                        style: AppTextStyles.caption.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final docsAsync = ref.watch(programDocumentsProvider(
      patientId: program.patientId,
      programId: program.id,
    ));
    final docs = docsAsync.value ?? [];

    final hasAnyFindings = (program.examination?.isNotEmpty ?? false) ||
        (program.imagingNotes?.isNotEmpty ?? false) ||
        (program.exaggeratingPositions?.isNotEmpty ?? false) ||
        (program.relievingPositions?.isNotEmpty ?? false) ||
        (program.notes?.isNotEmpty ?? false) ||
        docs.isNotEmpty;

    if (!hasAnyFindings) return const SizedBox.shrink();

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
          Text(
            'Clinical Assessment & Findings',
            style: AppTextStyles.cardTitle.copyWith(color: cs.onSurface),
          ),
          const SizedBox(height: AppSizes.p12),
          _buildFindingSection(
            context: context,
            title: AppStrings.examination,
            content: program.examination,
            icon: Icons.assignment_outlined,
          ),
          _buildFindingSection(
            context: context,
            title: AppStrings.imagingNotes,
            content: program.imagingNotes,
            icon: Icons.image_search_outlined,
          ),
          _buildImagingAttachments(context, docs),
          _buildFindingSection(
            context: context,
            title: AppStrings.exaggeratingPositions,
            content: program.exaggeratingPositions,
            icon: Icons.trending_up_rounded,
          ),
          _buildFindingSection(
            context: context,
            title: AppStrings.relievingPositions,
            content: program.relievingPositions,
            icon: Icons.trending_down_rounded,
          ),
          _buildFindingSection(
            context: context,
            title: AppStrings.programNotes,
            content: program.notes,
            icon: Icons.notes_rounded,
          ),
        ],
      ),
    );
  }
}
