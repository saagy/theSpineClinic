library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/medical_records/domain/laterality.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_input.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_target_region.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_type.dart';

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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isBilateral = ModalityTargetRegion.isRegionBilateral(
      modalityType,
      regionInput.targetRegion,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.p10),
      padding: const EdgeInsets.all(AppSizes.p12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(AppSizes.r12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildRegionDropdown(context)),
              const SizedBox(width: AppSizes.p8),
              IconButton(
                icon: Icon(Icons.remove_circle_outline, color: cs.error, size: AppSizes.iconDefault),
                tooltip: AppStrings.delete,
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p8),
          Row(
            children: [
              if (isBilateral) ...[
                Expanded(child: _buildLateralitySelector()),
                const SizedBox(width: AppSizes.p12),
              ] else
                const Spacer(),
              _buildDurationStepper(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegionDropdown(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final String selected = regionInput.targetRegion.isNotEmpty
        ? regionInput.targetRegion
        : (availableRegions.isNotEmpty ? availableRegions.first.name : '');

    return DropdownButtonFormField<String>(
      initialValue: availableRegions.any((r) => r.name == selected)
          ? selected
          : (availableRegions.isNotEmpty ? availableRegions.first.name : null),
      isExpanded: true,
      decoration: InputDecoration(
        labelText: AppStrings.targetRegion,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.p12, vertical: AppSizes.p8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.r8)),
      ),
      items: availableRegions.map((r) {
        return DropdownMenuItem<String>(
          value: r.name,
          child: Text(r.name, style: AppTextStyles.body.copyWith(color: cs.onSurface)),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) {
          final isBilateral = ModalityTargetRegion.isRegionBilateral(modalityType, val);
          onChanged(regionInput.copyWith(targetRegion: val, laterality: isBilateral ? regionInput.laterality : null));
        }
      },
    );
  }

  Widget _buildLateralitySelector() {
    return SegmentedButton<Laterality?>(
      segments: const [
        ButtonSegment(value: Laterality.right, label: Text('Right')),
        ButtonSegment(value: Laterality.left, label: Text('Left')),
        ButtonSegment(value: Laterality.both, label: Text('Both')),
      ],
      selected: {regionInput.laterality},
      emptySelectionAllowed: true,
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: WidgetStatePropertyAll(AppTextStyles.captionBold),
      ),
      onSelectionChanged: (sel) {
        onChanged(regionInput.copyWith(laterality: sel.isEmpty ? null : sel.first));
      },
    );
  }

  Widget _buildDurationStepper(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final minutes = regionInput.timeMinutes;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8, vertical: AppSizes.p4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSizes.r8),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: minutes > 5 ? () => onChanged(regionInput.copyWith(timeMinutes: minutes - 5)) : null,
            borderRadius: BorderRadius.circular(AppSizes.r4),
            child: Icon(Icons.remove, size: 16, color: minutes > 5 ? cs.primary : cs.outline),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8),
            child: Text(AppStrings.durationFormat(minutes), style: AppTextStyles.captionBold.copyWith(color: cs.onSurface)),
          ),
          InkWell(
            onTap: minutes < 60 ? () => onChanged(regionInput.copyWith(timeMinutes: minutes + 5)) : null,
            borderRadius: BorderRadius.circular(AppSizes.r4),
            child: Icon(Icons.add, size: 16, color: minutes < 60 ? cs.primary : cs.outline),
          ),
        ],
      ),
    );
  }
}
