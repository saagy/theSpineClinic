library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/medical_records/domain/laterality.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_input.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_region_catalog.dart';
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

  bool get _isParaspinal =>
      modalityType == ModalityType.release &&
      regionInput.targetRegion.toLowerCase().startsWith('paraspinal');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isBilateral = ModalityTargetRegion.isRegionBilateral(modalityType, regionInput.targetRegion);
    final showDuration = ModalityTargetRegion.hasDuration(modalityType, regionInput.targetRegion);

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
          if (_isParaspinal) _buildParaspinalSubSelector(),
          if (isBilateral || showDuration) ...[
            const SizedBox(height: AppSizes.p8),
            Row(
              children: [
                if (isBilateral) ...[
                  Expanded(child: _buildLateralitySelector()),
                  if (showDuration) const SizedBox(width: AppSizes.p12),
                ] else if (showDuration)
                  const Spacer(),
                if (showDuration) _buildDurationStepper(context),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRegionDropdown(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selectedRaw = regionInput.targetRegion.isNotEmpty
        ? regionInput.targetRegion
        : (availableRegions.isNotEmpty ? availableRegions.first.name : '');
    final dropdownValue = _isParaspinal
        ? 'Paraspinal'
        : (availableRegions.any((r) => r.name == selectedRaw) ? selectedRaw : (availableRegions.isNotEmpty ? availableRegions.first.name : ''));

    return DropdownButtonFormField<String>(
      initialValue: dropdownValue.isNotEmpty ? dropdownValue : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: AppStrings.targetRegion,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.p12, vertical: AppSizes.p8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.r8)),
      ),
      items: availableRegions.map((r) => DropdownMenuItem(value: r.name, child: Text(r.name, style: AppTextStyles.body.copyWith(color: cs.onSurface)))).toList(),
      onChanged: (val) {
        if (val == null) return;
        if (val == 'Paraspinal') {
          onChanged(regionInput.copyWith(targetRegion: 'Paraspinal (Cervical)', laterality: regionInput.laterality ?? Laterality.both));
        } else {
          final isBilateral = ModalityTargetRegion.isRegionBilateral(modalityType, val);
          onChanged(regionInput.copyWith(targetRegion: val, laterality: isBilateral ? (regionInput.laterality ?? Laterality.both) : null));
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
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'Cervical', label: Text('Cervical')),
          ButtonSegment(value: 'Thoracic', label: Text('Thoracic')),
          ButtonSegment(value: 'Lumbar', label: Text('Lumbar')),
          ButtonSegment(value: 'SI', label: Text('SI')),
        ],
        selected: {currentSub},
        showSelectedIcon: false,
        style: const ButtonStyle(visualDensity: VisualDensity.compact, tapTargetSize: MaterialTapTargetSize.shrinkWrap, textStyle: WidgetStatePropertyAll(AppTextStyles.captionBold)),
        onSelectionChanged: (sel) => sel.isNotEmpty ? onChanged(regionInput.copyWith(targetRegion: 'Paraspinal (${sel.first})')) : null,
      ),
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
      style: const ButtonStyle(visualDensity: VisualDensity.compact, tapTargetSize: MaterialTapTargetSize.shrinkWrap, textStyle: WidgetStatePropertyAll(AppTextStyles.captionBold)),
      onSelectionChanged: (sel) => onChanged(regionInput.copyWith(laterality: sel.isEmpty ? null : sel.first)),
    );
  }

  Widget _buildDurationStepper(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final min = regionInput.timeMinutes;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8, vertical: AppSizes.p4),
      decoration: BoxDecoration(color: cs.surfaceContainerLowest, borderRadius: BorderRadius.circular(AppSizes.r8), border: Border.all(color: cs.outlineVariant)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: min > 5 ? () => onChanged(regionInput.copyWith(timeMinutes: min - 5)) : null,
            borderRadius: BorderRadius.circular(AppSizes.r4),
            child: Icon(Icons.remove, size: 16, color: min > 5 ? cs.primary : cs.outline),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8),
            child: Text(AppStrings.durationFormat(min), style: AppTextStyles.captionBold.copyWith(color: cs.onSurface)),
          ),
          InkWell(
            onTap: min < 60 ? () => onChanged(regionInput.copyWith(timeMinutes: min + 5)) : null,
            borderRadius: BorderRadius.circular(AppSizes.r4),
            child: Icon(Icons.add, size: 16, color: min < 60 ? cs.primary : cs.outline),
          ),
        ],
      ),
    );
  }
}
