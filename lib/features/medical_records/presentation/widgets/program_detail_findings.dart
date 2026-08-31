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

/// Card displaying clinical examination, imaging findings, scans, and position observations.
class ProgramDetailFindings extends ConsumerWidget {
  const ProgramDetailFindings({super.key, required this.program});

  final PatientProgram program;

  Widget _buildFieldTile(BuildContext context, {required String label, required String? value, required IconData icon}) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.p8),
      padding: const EdgeInsets.all(AppSizes.p12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSizes.r12),
        border: Border.all(color: cs.outlineVariant.withAlpha(120)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: cs.primary),
              const SizedBox(width: AppSizes.p6),
              Text(label, style: AppTextStyles.captionBold.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: AppSizes.p6),
          Text(value.trim(), style: AppTextStyles.body.copyWith(color: cs.onSurface)),
        ],
      ),
    );
  }

  Widget _buildPair(BuildContext context, {required Widget first, required Widget second, required bool isWide}) {
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: first),
          const SizedBox(width: AppSizes.p8),
          Expanded(child: second),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [first, second],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final docsAsync = ref.watch(programDocumentsProvider(patientId: program.patientId, programId: program.id));
    final docs = docsAsync.value ?? [];

    final hasExam = program.examination?.isNotEmpty ?? false;
    final hasImaging = program.imagingNotes?.isNotEmpty ?? false;
    final hasExagg = program.exaggeratingPositions?.isNotEmpty ?? false;
    final hasRelief = program.relievingPositions?.isNotEmpty ?? false;
    final hasNotes = program.notes?.isNotEmpty ?? false;

    if (!hasExam && !hasImaging && !hasExagg && !hasRelief && !hasNotes && docs.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= 500;

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
                children: [
                  Icon(Icons.assignment_outlined, size: AppSizes.iconSmall, color: cs.primary),
                  const SizedBox(width: AppSizes.p8),
                  Text(AppStrings.clinicalFindingsSection, style: AppTextStyles.cardTitle.copyWith(color: cs.onSurface)),
                ],
              ),
              const SizedBox(height: AppSizes.p12),
              if (hasExam && hasImaging)
                _buildPair(
                  context,
                  first: _buildFieldTile(context, label: AppStrings.examination, value: program.examination, icon: Icons.health_and_safety_outlined),
                  second: _buildFieldTile(context, label: AppStrings.imagingNotes, value: program.imagingNotes, icon: Icons.image_search_outlined),
                  isWide: isWide,
                )
              else ...[
                if (hasExam) _buildFieldTile(context, label: AppStrings.examination, value: program.examination, icon: Icons.health_and_safety_outlined),
                if (hasImaging) _buildFieldTile(context, label: AppStrings.imagingNotes, value: program.imagingNotes, icon: Icons.image_search_outlined),
              ],
              if (docs.isNotEmpty) ...[
                ProgramMediaReel(
                  documents: docs,
                  onOpenDocument: (idx) => ProgramGalleryViewerScreen.open(
                    context,
                    documents: docs,
                    initialIndex: idx,
                    patientId: program.patientId,
                    programId: program.id,
                  ),
                ),
                const SizedBox(height: AppSizes.p8),
              ],
              if (hasExagg && hasRelief)
                _buildPair(
                  context,
                  first: _buildFieldTile(context, label: AppStrings.exaggeratingPositions, value: program.exaggeratingPositions, icon: Icons.trending_up_rounded),
                  second: _buildFieldTile(context, label: AppStrings.relievingPositions, value: program.relievingPositions, icon: Icons.trending_down_rounded),
                  isWide: isWide,
                )
              else ...[
                if (hasExagg) _buildFieldTile(context, label: AppStrings.exaggeratingPositions, value: program.exaggeratingPositions, icon: Icons.trending_up_rounded),
                if (hasRelief) _buildFieldTile(context, label: AppStrings.relievingPositions, value: program.relievingPositions, icon: Icons.trending_down_rounded),
              ],
              if (hasNotes) _buildFieldTile(context, label: AppStrings.programNotes, value: program.notes, icon: Icons.notes_rounded),
            ],
          ),
        );
      },
    );
  }
}
