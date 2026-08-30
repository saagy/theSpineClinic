library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_medical_history.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

/// Renders the conditions content of a patient's medical history.
class MedicalHistoryContent extends StatelessWidget {
  const MedicalHistoryContent({
    super.key,
    required this.history,
    required this.canEdit,
    required this.patientId,
  });

  final PatientMedicalHistory? history;
  final bool canEdit;
  final String patientId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (history == null || !history!.hasAnyCondition) {
      return Container(
        padding: const EdgeInsets.all(AppSizes.p16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppSizes.r16),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: cs.primary,
              size: AppSizes.iconDefault,
            ),
            const SizedBox(width: AppSizes.p12),
            Expanded(
              child: Text(
                AppStrings.noMedicalHistoryRecorded,
                style: AppTextStyles.bodySecondary.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final h = history!;
    final conditions = <_ConditionItem>[
      if (h.hasDiabetes)
        _ConditionItem(
          label: h.hba1cValue != null && h.hba1cValue!.isNotEmpty
              ? '${AppStrings.diabetes} (${AppStrings.hba1c}: ${h.hba1cValue})'
              : AppStrings.diabetes,
          icon: Icons.water_drop_outlined,
        ),
      if (h.hasHypertension)
        const _ConditionItem(
          label: AppStrings.hypertension,
          icon: Icons.favorite_border,
        ),
      if (h.hasHyperlipidemia)
        const _ConditionItem(
          label: AppStrings.hyperlipidemia,
          icon: Icons.opacity_outlined,
        ),
      if (h.hasRheumatology)
        _ConditionItem(
          label: h.rheumatologyDetails != null &&
                  h.rheumatologyDetails!.isNotEmpty
              ? '${AppStrings.rheumatology}: ${h.rheumatologyDetails}'
              : AppStrings.rheumatology,
          icon: Icons.accessibility_new_outlined,
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSizes.r16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSizes.p8,
            runSpacing: AppSizes.p8,
            children: conditions.map((c) => _ConditionChip(item: c)).toList(),
          ),
          if (h.additionalNotes != null && h.additionalNotes!.isNotEmpty) ...[
            const SizedBox(height: AppSizes.p12),
            Container(
              padding: const EdgeInsets.all(AppSizes.p12),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(AppSizes.r8),
              ),
              child: Text(
                h.additionalNotes!,
                style: AppTextStyles.caption.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConditionItem {
  const _ConditionItem({required this.label, required this.icon});
  final String label;
  final IconData icon;
}

class _ConditionChip extends StatelessWidget {
  const _ConditionChip({required this.item});
  final _ConditionItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p10,
        vertical: AppSizes.p6,
      ),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(AppSizes.r999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            item.icon,
            size: AppSizes.iconSmall,
            color: cs.onSecondaryContainer,
          ),
          const SizedBox(width: AppSizes.p6),
          Flexible(
            child: Text(
              item.label,
              style: AppTextStyles.captionBold.copyWith(
                color: cs.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading skeleton for the medical history card.
class MedicalHistorySkeleton extends StatelessWidget {
  const MedicalHistorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonBox(
      height: 72,
      borderRadius: AppSizes.r16,
    );
  }
}
