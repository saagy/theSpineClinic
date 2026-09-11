import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_status.dart';

/// Compact active program row optimized for high-density overview screens.
class WorkspaceProgramCompactRow extends StatelessWidget {
  const WorkspaceProgramCompactRow({super.key, required this.program});
  final PatientProgram program;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final conditions = program.conditions
        .map((p) => p.condition?.conditionName)
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .toList();

    final String primaryCondition = conditions.isNotEmpty
        ? conditions.first
        : AppStrings.rehabilitationProgram;
    final int extraConditions = conditions.length > 1 ? conditions.length - 1 : 0;
    final String planName = program.activePlan?.planName ?? AppStrings.noActivePlan;

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
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.p14,
              vertical: AppSizes.p12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.p8,
                                vertical: AppSizes.p2,
                              ),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer.withAlpha(120),
                                borderRadius: BorderRadius.circular(AppSizes.r6),
                              ),
                              child: Text(
                                primaryCondition,
                                style: AppTextStyles.captionBold.copyWith(
                                  color: cs.onPrimaryContainer,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (extraConditions > 0) ...[
                            const SizedBox(width: AppSizes.p6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.p6,
                                vertical: AppSizes.p2,
                              ),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(AppSizes.r6),
                              ),
                              child: Text(
                                AppStrings.moreConditions(extraConditions),
                                style: AppTextStyles.captionMedium.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSizes.p6),
                      Row(
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
                          const SizedBox(width: AppSizes.p8),
                          Expanded(
                            child: Text(
                              planName,
                              style: AppTextStyles.caption.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.p8),
                Icon(
                  Icons.chevron_right,
                  size: AppSizes.p20,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
