import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_status.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_programs_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_program_compact_row.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_program_row.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_tab_header.dart';
import 'package:spine_clinic_app/shared/widgets/record_section.dart';

class WorkspacePrograms extends ConsumerWidget {
  const WorkspacePrograms({super.key, required this.patientId, this.overview = false, this.onViewAll});
  final String patientId;
  final bool overview;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = patientProgramsProvider(patientId);
    final canCreate = ref.watch(currentUserProvider).value?.isSeniorDoctor ?? false;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WorkspaceTabHeader(
          title: overview ? AppStrings.activePrograms : AppStrings.programs,
          actionLabel: !overview && canCreate ? AppStrings.newProgram : null,
          onAction: !overview && canCreate
              ? () {
                  if (ref.read(currentUserProvider).value?.isSeniorDoctor != true) return;
                  context.push(AppRoutes.newPatientProgram.replaceFirst(':id', patientId));
                }
              : null,
          trailing: overview && onViewAll != null
              ? TextButton(
                  onPressed: onViewAll,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8),
                  ),
                  child: const Text(AppStrings.allPrograms),
                )
              : null,
        ),
        const SizedBox(height: AppSizes.p12),
        RecordAsync(
          value: ref.watch(provider),
          onRetry: () => ref.invalidate(provider),
          data: (programs) {
            final active = programs.where((p) => p.status == ProgramStatus.active).toList();
            final archived = programs.where((p) => p.status != ProgramStatus.active).toList();

            if (overview) {
              if (active.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(AppSizes.p20),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(AppSizes.r12),
                    border: Border.all(color: cs.outlineVariant.withAlpha(80)),
                  ),
                  child: const RecordMessage(message: AppStrings.noActivePrograms),
                );
              }
              final displayed = active.take(2).toList();
              final int remaining = active.length - displayed.length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final program in displayed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.p8),
                      child: WorkspaceProgramCompactRow(program: program),
                    ),
                  if (remaining > 0 && onViewAll != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: onViewAll,
                        child: Text(
                          '${AppStrings.morePrograms(remaining)} · ${AppStrings.allPrograms}',
                          style: AppTextStyles.captionBold,
                        ),
                      ),
                    ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (active.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSizes.p20),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(AppSizes.r12),
                      border: Border.all(color: cs.outlineVariant.withAlpha(80)),
                    ),
                    child: const RecordMessage(message: AppStrings.noActivePrograms),
                  ),
                for (final program in active)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.p10),
                    child: WorkspaceProgramRow(program: program),
                  ),
                if (archived.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.p12),
                  ExpansionTile(
                    key: PageStorageKey('archived-programs/$patientId'),
                    tilePadding: EdgeInsets.zero,
                    title: Text(AppStrings.archivedProgramsCount(archived.length), style: AppTextStyles.bodyBold),
                    children: [
                      for (final program in archived)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSizes.p10),
                          child: WorkspaceProgramRow(program: program),
                        ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
