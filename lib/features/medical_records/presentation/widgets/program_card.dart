library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_status_badge.dart';

/// Card component rendering a program summary in the patient programs list.
class ProgramCard extends StatelessWidget {
  const ProgramCard({
    super.key,
    required this.program,
    required this.onTap,
  });

  final PatientProgram program;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final regions = program.affectedRegions;
    final conditions = program.conditions;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.p16,
        vertical: AppSizes.p8,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSizes.r16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.r16),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: AppSizes.iconSmall,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSizes.p6),
                      Text(
                        Formatters.formatDateMedium(program.createdAt),
                        style: AppTextStyles.captionBold.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  ProgramStatusBadge(status: program.status),
                ],
              ),
              const SizedBox(height: AppSizes.p12),
              if (regions.isNotEmpty) ...[
                Wrap(
                  spacing: AppSizes.p6,
                  runSpacing: AppSizes.p6,
                  children: regions.map((r) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.p8,
                        vertical: AppSizes.p4,
                      ),
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer,
                        borderRadius: BorderRadius.circular(AppSizes.r999),
                      ),
                      child: Text(
                        r.displayName,
                        style: AppTextStyles.captionBold.copyWith(
                          color: cs.onSecondaryContainer,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSizes.p8),
              ],
              if (conditions.isNotEmpty) ...[
                ...conditions.take(3).map((c) {
                  final name =
                      c.condition?.conditionName ?? 'Injured Condition';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.p4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            name,
                            style: AppTextStyles.bodySecondary.copyWith(
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (conditions.length > 3)
                  Text(
                    '+${conditions.length - 3} more conditions',
                    style: AppTextStyles.caption.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
              if (program.examination != null &&
                  program.examination!.trim().isNotEmpty) ...[
                const SizedBox(height: AppSizes.p8),
                Text(
                  program.examination!,
                  style: AppTextStyles.caption.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
