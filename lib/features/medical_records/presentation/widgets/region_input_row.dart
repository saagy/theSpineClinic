import 'package:spine_clinic_app/shared/widgets/form_field_label.dart';
import 'package:spine_clinic_app/shared/widgets/form_columns.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/treatment_duration_control.dart';

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/medical_records/domain/laterality.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_input.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_region_catalog.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_target_region.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_type.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/target_region_picker.dart';

/// Single region configuration row inside a modality configuration card.
class RegionInputRow extends StatelessWidget {
  const RegionInputRow({
    super.key,
    required this.modalityType,
    required this.regionInput,
    required this.availableRegions,
    required this.onChanged,
    required this.onDelete,
  });

  final ModalityType modalityType;
  final RegionInput regionInput;
  final List<ModalityTargetRegion> availableRegions;
  final ValueChanged<RegionInput> onChanged;
  final VoidCallback onDelete;

  bool get _isParaspinal =>
      modalityType == ModalityType.release &&
      regionInput.targetRegion.toLowerCase().startsWith('paraspinal');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isBilateral = ModalityTargetRegion.isRegionBilateral(
      modalityType,
      regionInput.targetRegion,
    );
    final showDuration = ModalityTargetRegion.hasDuration(
      modalityType,
      regionInput.targetRegion,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.p10),
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _buildRegionDropdown(context)),
              const SizedBox(width: AppSizes.p8),
              IconButton(
                icon: Icon(
                  Icons.remove_circle_outline,
                  color: cs.error,
                  size: AppSizes.iconDefault,
                ),
                tooltip: AppStrings.delete,
                onPressed: onDelete,
              ),
            ],
          ),
          if (_isParaspinal) _buildParaspinalSubSelector(),
          if (isBilateral || showDuration) ...[
            const SizedBox(height: AppSizes.p8),
            if (isBilateral && showDuration)
              FormColumns(
                breakpoint: AppSizes.formPairBreakpoint,
                first: _buildLateralitySelector(),
                second: TreatmentDurationControl(
                  minutes: regionInput.timeMinutes,
                  onChanged: (value) =>
                      onChanged(regionInput.copyWith(timeMinutes: value)),
                ),
              )
            else if (isBilateral)
              _buildLateralitySelector()
            else
              TreatmentDurationControl(
                minutes: regionInput.timeMinutes,
                onChanged: (value) =>
                    onChanged(regionInput.copyWith(timeMinutes: value)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildRegionDropdown(BuildContext context) {
    final selectedRaw = regionInput.targetRegion.isNotEmpty
        ? regionInput.targetRegion
        : (availableRegions.isNotEmpty ? availableRegions.first.name : '');
    final dropdownValue = _isParaspinal
        ? 'Paraspinal'
        : (availableRegions.any((r) => r.name == selectedRaw)
              ? selectedRaw
              : (availableRegions.isNotEmpty
                    ? availableRegions.first.name
                    : ''));

    return TargetRegionPicker(
      label: modalityType == ModalityType.exercise
          ? AppStrings.exerciseTarget
          : AppStrings.targetRegion,
      value: dropdownValue,
      regions: availableRegions,
      onChanged: (val) {
        if (val == 'Paraspinal') {
          onChanged(
            regionInput.copyWith(
              targetRegion: 'Paraspinal (Cervical)',
              laterality: regionInput.laterality ?? Laterality.both,
            ),
          );
        } else {
          final isBilateral = ModalityTargetRegion.isRegionBilateral(
            modalityType,
            val,
          );
          onChanged(
            regionInput.copyWith(
              targetRegion: val,
              clearLaterality: !isBilateral,
              laterality: isBilateral
                  ? (regionInput.laterality ?? Laterality.both)
                  : null,
            ),
          );
        }
      },
    );
  }

  Widget _buildParaspinalSubSelector() {
    String currentSub = 'Cervical';
    for (final opt in ModalityRegionCatalog.paraspinalSubOptions) {
      if (regionInput.targetRegion.contains(opt)) {
        currentSub = opt;
        break;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.p8),
      child: FormFieldLabel(
        label: AppStrings.spinalLevel,
        child: Wrap(
          spacing: AppSizes.p6,
          runSpacing: AppSizes.p4,
          children: [
            for (final option in const {
              'Cervical': AppStrings.cervical,
              'Thoracic': AppStrings.thoracic,
              'Lumbar': AppStrings.lumbar,
              'SI': AppStrings.sacroiliacShort,
            }.entries)
              ChoiceChip(
                label: Text(option.value, style: AppTextStyles.captionBold),
                selected: currentSub == option.key,
                showCheckmark: false,
                onSelected: (_) => onChanged(
                  regionInput.copyWith(
                    targetRegion: 'Paraspinal (${option.key})',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLateralitySelector() => FormFieldLabel(
    label: AppStrings.treatmentSide,
    child: SegmentedButton<Laterality>(
      segments: const [
        ButtonSegment(
          value: Laterality.left,
          label: Text(AppStrings.lateralityLeft),
        ),
        ButtonSegment(
          value: Laterality.right,
          label: Text(AppStrings.lateralityRight),
        ),
        ButtonSegment(
          value: Laterality.both,
          label: Text(AppStrings.bilateral),
        ),
      ],
      selected: {regionInput.laterality ?? Laterality.both},
      showSelectedIcon: false,
      style: const ButtonStyle(
        minimumSize: WidgetStatePropertyAll(
          Size(AppSizes.tappableMin, AppSizes.tappableMin),
        ),
        textStyle: WidgetStatePropertyAll(AppTextStyles.captionBold),
      ),
      onSelectionChanged: (selected) =>
          onChanged(regionInput.copyWith(laterality: selected.first)),
    ),
  );
}
