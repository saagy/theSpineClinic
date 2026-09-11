import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_status.dart';

/// Full-detail program row for the Programs tab.
class WorkspaceProgramRow extends StatelessWidget {
  const WorkspaceProgramRow({super.key, required this.program});
  final PatientProgram program;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final conditions = program.conditions
        .map((p) => p.condition?.conditionName)
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSizes.r12),
        border: Border.all(color: cs.outlineVariant.withAlpha(90)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.r12),
          onTap: () => context.push(
            AppRoutes.patientProgramDetail
                .replaceFirst(':id', program.patientId)
                .replaceFirst(':programId', program.id),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSizes.p6,
                        runSpacing: AppSizes.p4,
                        children: [
                          for (final cond in conditions.take(3))
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.p8,
                                vertical: AppSizes.p2,
                              ),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer.withAlpha(120),
                                borderRadius: BorderRadius.circular(AppSizes.r6),
                              ),
                              child: Text(
                                cond,
                                style: AppTextStyles.captionBold.copyWith(
                                  color: cs.onPrimaryContainer,
                                ),
                              ),
                            ),
                          if (conditions.isEmpty)
                            const Text(
                              AppStrings.rehabilitationProgram,
                              style: AppTextStyles.bodyBold,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.p8),
                      Text(
                        program.activePlan?.planName ?? AppStrings.noActivePlan,
                        style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
                      ),
                      const SizedBox(height: AppSizes.p8),
                      Wrap(
                        spacing: AppSizes.p8,
                        runSpacing: AppSizes.p4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.p6,
                              vertical: AppSizes.p2,
                            ),
                            decoration: BoxDecoration(
                              color: program.status == ProgramStatus.active
                                  ? cs.secondaryContainer.withAlpha(100)
                                  : cs.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(AppSizes.r4),
                            ),
                            child: Text(
                              program.status.displayLabel,
                              style: AppTextStyles.captionBold.copyWith(
                                color: program.status == ProgramStatus.active
                                    ? cs.primary
                                    : cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Text(
                            Formatters.formatDateMedium(program.createdAt),
                            style: AppTextStyles.caption.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevron_right, size: 18, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
