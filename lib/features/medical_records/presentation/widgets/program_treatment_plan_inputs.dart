library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/medical_records/domain/body_region.dart';
import 'package:spine_clinic_app/features/medical_records/domain/laterality.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_input.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_target_region.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_type.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/modality_chip_selector.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/modality_config_card.dart';
import 'package:spine_clinic_app/shared/widgets/app_text_field.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';

/// Form section widget allowing doctors to configure treatment plan modalities inline.
class ProgramTreatmentPlanInputs extends StatelessWidget {
  const ProgramTreatmentPlanInputs({
    super.key,
    required this.nameController,
    required this.notesController,
    required this.selectedModalities,
    required this.modalityInputs,
    required this.onModalitiesChanged,
    required this.onModalityInputChanged,
    this.affectedRegions = const {},
  });

  final TextEditingController nameController;
  final TextEditingController notesController;
  final Set<ModalityType> selectedModalities;
  final Map<ModalityType, ModalityInput> modalityInputs;
  final ValueChanged<Set<ModalityType>> onModalitiesChanged;
  final void Function(ModalityType type, ModalityInput input) onModalityInputChanged;
  final Set<BodyRegion> affectedRegions;

  void _handleToggle(ModalityType type, bool isSelected) {
    final updated = Set<ModalityType>.from(selectedModalities);
    if (isSelected) {
      updated.add(type);
      final current = modalityInputs[type] ?? ModalityInput(modalityType: type);
      if (type.hasRegionSubSelections && current.regions.isEmpty) {
        final initialRegion = _resolveSmartRegion(type);
        if (initialRegion != null) {
          final isBilateral = ModalityTargetRegion.isRegionBilateral(type, initialRegion);
          final target = initialRegion == 'Paraspinal' ? 'Paraspinal (Cervical)' : initialRegion;
          onModalityInputChanged(
            type,
            current.copyWith(regions: [
              RegionInput(
                targetRegion: target,
                laterality: isBilateral ? Laterality.both : null,
                timeMinutes: 15,
              )
            ]),
          );
        }
      }
    } else {
      updated.remove(type);
    }
    onModalitiesChanged(updated);
  }

  String? _resolveSmartRegion(ModalityType type) {
    final available = ModalityTargetRegion.regionsFor(type);
    if (available.isEmpty) return null;

    for (final bodyRegion in affectedRegions) {
      final name = bodyRegion.displayName.toLowerCase();
      final match = available.where((r) {
        final rName = r.name.toLowerCase();
        return rName.contains(name) || name.contains(rName);
      }).firstOrNull;
      if (match != null) return match.name;
    }
    return available.first.name;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SectionCard(
      title: AppStrings.treatmentPlanSection,
      action: selectedModalities.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8, vertical: AppSizes.p2),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(AppSizes.r999),
              ),
              child: Text(
                AppStrings.modalitiesCount(selectedModalities.length),
                style: AppTextStyles.captionBold.copyWith(color: cs.onPrimaryContainer),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.treatmentPlanSectionSubtitle,
            style: AppTextStyles.bodySecondary.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: AppSizes.p16),
          AppTextField(
            controller: nameController,
            labelText: AppStrings.planName,
            hintText: AppStrings.planNameHint,
          ),
          const SizedBox(height: AppSizes.p16),
          AppTextField(
            controller: notesController,
            labelText: AppStrings.planNotes,
            hintText: AppStrings.planNotesHint,
            maxLines: 2,
          ),
          const SizedBox(height: AppSizes.p16),
          Text(
            AppStrings.selectModalities,
            style: AppTextStyles.cardTitle.copyWith(color: cs.onSurface),
          ),
          const SizedBox(height: AppSizes.p8),
          ModalityChipSelector(
            selectedModalities: selectedModalities,
            onToggle: (type) => _handleToggle(type, !selectedModalities.contains(type)),
          ),
          const SizedBox(height: AppSizes.p16),
          if (selectedModalities.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.p16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppSizes.r16),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Text(
                AppStrings.noModalitiesSelected,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondary.copyWith(color: cs.onSurfaceVariant),
              ),
            )
          else
            ...ModalityType.values.where(selectedModalities.contains).map((type) {
              return ModalityConfigCard(
                key: ValueKey(type),
                modalityType: type,
                isSelected: true,
                modalityInput: modalityInputs[type] ?? ModalityInput(modalityType: type),
                onToggle: (selected) => _handleToggle(type, selected),
                onRemove: () => _handleToggle(type, false),
                onModalityChanged: (input) => onModalityInputChanged(type, input),
              );
            }),
        ],
      ),
    );
  }
}
