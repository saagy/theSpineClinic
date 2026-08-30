library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/screens/program_gallery_viewer_screen.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_media_reel.dart';
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
            AppStrings.clinicalFindingsSection,
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
          ProgramMediaReel(
            documents: docs,
            onOpenDocument: (initialIndex) {
              ProgramGalleryViewerScreen.open(
                context,
                documents: docs,
                initialIndex: initialIndex,
              );
            },
          ),
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
