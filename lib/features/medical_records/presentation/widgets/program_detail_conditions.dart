import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/shared/widgets/record_section.dart';

class ProgramDetailConditions extends StatelessWidget {
  const ProgramDetailConditions({super.key, required this.program});
  final PatientProgram program;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final regions = program.affectedRegions.toList()..sort((a, b) => a.displayName.compareTo(b.displayName));

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.affectedRegions, style: AppTextStyles.headingSmall.copyWith(color: cs.onSurface)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8, vertical: AppSizes.p2),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer.withAlpha(120),
                  borderRadius: BorderRadius.circular(AppSizes.r6),
                ),
                child: Text(
                  AppStrings.conditionsCount(program.conditions.length),
                  style: AppTextStyles.captionBold.copyWith(color: cs.onSecondaryContainer),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p14),
          if (regions.isEmpty)
            const RecordMessage(message: AppStrings.noConditionsRecorded)
          else
            for (final region in regions) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.p12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.activity, size: 14, color: cs.primary),
                        const SizedBox(width: AppSizes.p6),
                        Text(region.displayName, style: AppTextStyles.captionBold.copyWith(color: cs.primary)),
                      ],
                    ),
                    const SizedBox(height: AppSizes.p8),
                    Wrap(
                      spacing: AppSizes.p8,
                      runSpacing: AppSizes.p6,
                      children: program.conditions
                          .where((c) => c.condition?.region == region)
                          .map((c) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p10, vertical: AppSizes.p6),
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(AppSizes.r8),
                                  border: Border.all(color: cs.outlineVariant.withAlpha(80)),
                                ),
                                child: Text(
                                  c.condition?.conditionName ?? AppStrings.conditionUnspecified,
                                  style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }
}
