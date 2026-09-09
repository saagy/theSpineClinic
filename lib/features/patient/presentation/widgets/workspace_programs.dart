import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_status.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_programs_providers.dart';
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
    return RecordSection(
      showTitle: overview,
      title: overview ? AppStrings.activePrograms : AppStrings.programs,
      action: overview
          ? AppStrings.allPrograms
          : canCreate
          ? AppStrings.newProgram
          : null,
      primaryAction: !overview,
      onAction: overview
          ? onViewAll
          : () {
              if (ref.read(currentUserProvider).value?.isSeniorDoctor != true) return;
              context.push(AppRoutes.newPatientProgram.replaceFirst(':id', patientId));
            },
      child: RecordAsync(
        value: ref.watch(provider),
        onRetry: () => ref.invalidate(provider),
        data: (programs) {
          final active = programs.where((p) => p.status == ProgramStatus.active).toList();
          final archived = programs.where((p) => p.status != ProgramStatus.active).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (active.isEmpty) const RecordMessage(message: AppStrings.noActivePrograms),
              for (final program in active) WorkspaceProgramRow(program: program),
              if (!overview && archived.isNotEmpty)
                ExpansionTile(
                  key: PageStorageKey('archived-programs/$patientId'),
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    AppStrings.archivedProgramsCount(archived.length),
                    style: AppTextStyles.bodyBold,
                  ),
                  children: [for (final program in archived) WorkspaceProgramRow(program: program)],
                ),
            ],
          );
        },
      ),
    );
  }
}

class WorkspaceProgramRow extends StatelessWidget {
  const WorkspaceProgramRow({super.key, required this.program});
  final PatientProgram program;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final conditions = program.conditions
        .map((p) => p.condition?.conditionName)
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .toList();
    return Material(
      color: colors.surface,
      child: InkWell(
        onTap: () => context.push(
          AppRoutes.patientProgramDetail
              .replaceFirst(':id', program.patientId)
              .replaceFirst(':programId', program.id),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.p20),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.outlineVariant)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conditions.isEmpty ? AppStrings.rehabilitationProgram : conditions.join(', '),
                      style: AppTextStyles.bodyBold,
                    ),
                    const SizedBox(height: AppSizes.p6),
                    Text(
                      program.activePlan?.planName ?? AppStrings.noActivePlan,
                      style: AppTextStyles.body.copyWith(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSizes.p8),
                    Wrap(
                      spacing: AppSizes.p12,
                      runSpacing: AppSizes.p4,
                      children: [
                        Text(
                          program.status.displayLabel,
                          style: AppTextStyles.captionBold.copyWith(
                            color: program.status == ProgramStatus.active
                                ? colors.primary
                                : colors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          Formatters.formatDateMedium(program.createdAt),
                          style: AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.p16),
              Icon(LucideIcons.chevron_right, size: AppSizes.iconDefault, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
