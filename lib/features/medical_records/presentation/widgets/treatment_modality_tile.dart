library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/medical_records/domain/plan_modality.dart';

/// Clean row element for a modality inside a treatment plan table.
class TreatmentModalityTile extends StatelessWidget {
  const TreatmentModalityTile({
    super.key,
    required this.modality,
    this.showDivider = true,
  });

  final PlanModality modality;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.p10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      modality.modalityType.displayLabel,
                      style: AppTextStyles.bodyBold.copyWith(color: cs.onSurface),
                    ),
                    if (modality.notes != null && modality.notes!.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSizes.p2),
                      Text(
                        modality.notes!.trim(),
                        style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.p8),
              Expanded(
                flex: 6,
                child: modality.regions.isNotEmpty
                    ? Wrap(
                        alignment: WrapAlignment.end,
                        spacing: AppSizes.p4,
                        runSpacing: AppSizes.p4,
                        children: modality.regions.map((region) {
                          final lat = region.laterality != null
                              ? ' (${region.laterality!.shortLabel})'
                              : '';
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.p8,
                              vertical: AppSizes.p2,
                            ),
                            decoration: BoxDecoration(
                              color: cs.secondaryContainer.withAlpha(90),
                              borderRadius: BorderRadius.circular(AppSizes.r8),
                              border: Border.all(color: cs.outlineVariant.withAlpha(100)),
                            ),
                            child: Text(
                              '${region.targetRegion}$lat · ${region.timeMinutes}m',
                              style: AppTextStyles.captionBold.copyWith(
                                color: cs.onSecondaryContainer,
                              ),
                            ),
                          );
                        }).toList(),
                      )
                    : Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.p8,
                            vertical: AppSizes.p2,
                          ),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest.withAlpha(80),
                            borderRadius: BorderRadius.circular(AppSizes.r8),
                          ),
                          child: Text(
                            'General Technique',
                            style: AppTextStyles.caption.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: cs.outlineVariant.withAlpha(60),
          ),
      ],
    );
  }
}
