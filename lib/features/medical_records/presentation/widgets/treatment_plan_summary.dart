import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_target_region.dart';
import 'package:spine_clinic_app/features/medical_records/domain/treatment_plan.dart';
import 'treatment_modality_tile.dart';

class TreatmentPlanSummary extends StatelessWidget {
  const TreatmentPlanSummary({super.key, required this.plan});
  final TreatmentPlan plan;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = plan.modalities.fold<int>(
      0,
      (sum, modality) =>
          sum +
          modality.regions
              .where((r) => ModalityTargetRegion.hasDuration(modality.modalityType, r.targetRegion))
              .fold<int>(0, (minutes, region) => minutes + region.timeMinutes),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(plan.planName, style: AppTextStyles.bodyBold.copyWith(color: cs.onSurface)),
        const SizedBox(height: AppSizes.p6),
        Wrap(
          spacing: AppSizes.p12,
          runSpacing: AppSizes.p4,
          children: [
            Text(
              AppStrings.createdOn(Formatters.formatDateMedium(plan.createdAt)),
              style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
            ),
            Text(
              AppStrings.modalitiesCount(plan.modalities.length),
              style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
            ),
            if (total > 0)
              Text(
                AppStrings.totalDurationFormat(total),
                style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
              ),
          ],
        ),
        if (plan.notes?.trim().isNotEmpty == true) ...[
          const SizedBox(height: AppSizes.p8),
          Text(plan.notes!.trim(), style: AppTextStyles.bodySecondary.copyWith(color: cs.onSurfaceVariant)),
        ],
        const SizedBox(height: AppSizes.p12),
        for (int i = 0; i < plan.modalities.length; i++)
          TreatmentModalityTile(modality: plan.modalities[i], showDivider: i < plan.modalities.length - 1),
      ],
    );
  }
}
