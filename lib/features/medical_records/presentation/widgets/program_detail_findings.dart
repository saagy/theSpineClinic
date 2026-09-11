import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
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
    final cs = Theme.of(context).colorScheme;

    final findings = <String, String?>{
      AppStrings.examination: program.examination,
      AppStrings.imagingNotes: program.imagingNotes,
      AppStrings.exaggeratingPositions: program.exaggeratingPositions,
      AppStrings.relievingPositions: program.relievingPositions,
      AppStrings.programNotes: program.notes,
    };
    final activeEntries = findings.entries.where((e) => e.value?.trim().isNotEmpty == true).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.p16),
      padding: const EdgeInsets.all(AppSizes.p20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSizes.r12),
        border: Border.all(color: cs.outlineVariant.withAlpha(90)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.clinicalFindingsSection, style: AppTextStyles.headingSmall.copyWith(color: cs.onSurface)),
          const SizedBox(height: AppSizes.p14),
          if (activeEntries.isEmpty)
            const RecordMessage(message: AppStrings.clinicalFindingsNotRecorded)
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 600;
                final colWidth = isWide ? (constraints.maxWidth - AppSizes.p12) / 2 : constraints.maxWidth;
                return Wrap(
                  spacing: AppSizes.p12,
                  runSpacing: AppSizes.p12,
                  children: [
                    for (final entry in activeEntries)
                      SizedBox(
                        width: colWidth,
                        child: Container(
                          padding: const EdgeInsets.all(AppSizes.p12),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(AppSizes.r8),
                            border: Border.all(color: cs.outlineVariant.withAlpha(80)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.key, style: AppTextStyles.captionBold.copyWith(color: cs.onSurfaceVariant)),
                              const SizedBox(height: AppSizes.p4),
                              SelectableText(entry.value!.trim(), style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface)),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          const SizedBox(height: AppSizes.p16),
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
