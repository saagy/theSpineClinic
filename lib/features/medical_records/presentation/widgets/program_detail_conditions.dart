library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';

/// Card component presenting affected anatomical regions and specific condition tags.
class ProgramDetailConditions extends StatelessWidget {
  const ProgramDetailConditions({super.key, required this.program});

  final PatientProgram program;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final regions = program.affectedRegions.toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));

    if (regions.isEmpty) return const SizedBox.shrink();

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
              Icon(Icons.accessibility_new_rounded, size: AppSizes.iconSmall, color: cs.primary),
              const SizedBox(width: AppSizes.p8),
              Text(AppStrings.affectedRegions, style: AppTextStyles.cardTitle.copyWith(color: cs.onSurface)),
              const Spacer(),
              Text(
                AppStrings.regionsAndConditionsCount(regions.length, program.conditions.length),
                style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p12),
          ...regions.map((region) {
            final conditions = program.conditions.where((c) => c.condition?.region == region).toList();

            return Container(
              margin: const EdgeInsets.only(bottom: AppSizes.p8),
              padding: const EdgeInsets.all(AppSizes.p12),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(AppSizes.r12),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8, vertical: AppSizes.p2),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(AppSizes.r999),
                        ),
                        child: Text(region.displayName, style: AppTextStyles.captionBold.copyWith(color: cs.onPrimaryContainer)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.p8),
                  Wrap(
                    spacing: AppSizes.p6,
                    runSpacing: AppSizes.p6,
                    children: conditions.map((c) {
                      final name = c.condition?.conditionName ?? AppStrings.conditionUnspecified;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8, vertical: AppSizes.p4),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest.withAlpha(90),
                          borderRadius: BorderRadius.circular(AppSizes.r8),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: Text(name, style: AppTextStyles.captionBold.copyWith(color: cs.onSurface)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
