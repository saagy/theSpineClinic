library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';

/// Card component presenting the affected regions and specific conditions.
class ProgramDetailConditions extends StatelessWidget {
  const ProgramDetailConditions({super.key, required this.program});

  final PatientProgram program;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final regions = program.affectedRegions.toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));

    if (regions.isEmpty) {
      return const SizedBox.shrink();
    }

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
              Icon(
                Icons.accessibility_new_rounded,
                size: AppSizes.iconSmall,
                color: cs.primary,
              ),
              const SizedBox(width: AppSizes.p8),
              Text(
                AppStrings.affectedRegions,
                style: AppTextStyles.cardTitle.copyWith(color: cs.onSurface),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p12),
          ...regions.map((region) {
            final conditionsForRegion = program.conditions.where(
              (c) => c.condition?.region == region,
            );

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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.p8,
                      vertical: AppSizes.p2,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(AppSizes.r999),
                    ),
                    child: Text(
                      region.displayName,
                      style: AppTextStyles.captionBold.copyWith(
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.p8),
                  ...conditionsForRegion.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(
                        left: AppSizes.p4,
                        bottom: AppSizes.p4,
                      ),
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
                              c.condition?.conditionName ??
                                  AppStrings.conditionUnspecified,
                              style: AppTextStyles.body.copyWith(
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
