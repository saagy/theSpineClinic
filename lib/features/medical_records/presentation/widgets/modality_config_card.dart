library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_input.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_target_region.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_type.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/region_input_row.dart';
import 'package:spine_clinic_app/shared/widgets/app_text_field.dart';

/// Card component to configure a single treatment modality and its target regions.
class ModalityConfigCard extends StatefulWidget {
  const ModalityConfigCard({
    super.key,
    required this.modalityType,
    required this.isSelected,
    required this.modalityInput,
    required this.onToggle,
    required this.onModalityChanged,
  });

  final ModalityType modalityType;
  final bool isSelected;
  final ModalityInput modalityInput;
  final ValueChanged<bool> onToggle;
  final ValueChanged<ModalityInput> onModalityChanged;

  @override
  State<ModalityConfigCard> createState() => _ModalityConfigCardState();
}

class _ModalityConfigCardState extends State<ModalityConfigCard> {
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.modalityInput.notes ?? '');
  }

  @override
  void didUpdateWidget(covariant ModalityConfigCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.modalityInput.notes != oldWidget.modalityInput.notes &&
        widget.modalityInput.notes != _notesController.text) {
      _notesController.text = widget.modalityInput.notes ?? '';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _addRegion() {
    final regions = ModalityTargetRegion.regionsFor(widget.modalityType);
    final defaultRegion = regions.isNotEmpty ? regions.first.name : 'Target Region';

    final updated = [
      ...widget.modalityInput.regions,
      RegionInput(targetRegion: defaultRegion, timeMinutes: 15),
    ];
    widget.onModalityChanged(widget.modalityInput.copyWith(regions: updated));
  }

  void _removeRegion(int index) {
    final updated = List<RegionInput>.from(widget.modalityInput.regions)..removeAt(index);
    widget.onModalityChanged(widget.modalityInput.copyWith(regions: updated));
  }

  void _updateRegion(int index, RegionInput input) {
    final updated = List<RegionInput>.from(widget.modalityInput.regions);
    updated[index] = input;
    widget.onModalityChanged(widget.modalityInput.copyWith(regions: updated));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.p12),
      decoration: BoxDecoration(
        color: widget.isSelected ? cs.primaryContainer.withAlpha(25) : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSizes.r16),
        border: Border.all(
          color: widget.isSelected ? cs.primary : cs.outlineVariant,
          width: widget.isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(cs),
          if (widget.isSelected) _buildBody(),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return InkWell(
      onTap: () => widget.onToggle(!widget.isSelected),
      borderRadius: BorderRadius.circular(AppSizes.r16),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Row(
          children: [
            Checkbox(
              value: widget.isSelected,
              onChanged: (val) => widget.onToggle(val ?? false),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r4)),
            ),
            const SizedBox(width: AppSizes.p8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.modalityType.displayLabel,
                    style: AppTextStyles.cardTitle.copyWith(
                      color: widget.isSelected ? cs.primary : cs.onSurface,
                    ),
                  ),
                  if (widget.modalityType.hasRegionSubSelections && widget.isSelected)
                    Text(
                      AppStrings.regionsCount(widget.modalityInput.regions.length),
                      style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            Icon(
              widget.isSelected ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: cs.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final availableRegions = ModalityTargetRegion.regionsFor(widget.modalityType);

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.p16, 0, AppSizes.p16, AppSizes.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: AppSizes.p8),
          if (widget.modalityType.hasRegionSubSelections) ...[
            const SizedBox(height: AppSizes.p8),
            ...widget.modalityInput.regions.asMap().entries.map((entry) {
              return RegionInputRow(
                modalityType: widget.modalityType,
                regionInput: entry.value,
                availableRegions: availableRegions,
                onChanged: (r) => _updateRegion(entry.key, r),
                onDelete: () => _removeRegion(entry.key),
              );
            }),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text(AppStrings.addRegion),
                onPressed: _addRegion,
              ),
            ),
            const SizedBox(height: AppSizes.p8),
          ],
          AppTextField(
            controller: _notesController,
            labelText: AppStrings.modalityNotes,
            hintText: AppStrings.modalityNotesHint,
            maxLines: 2,
            onChanged: (val) {
              widget.onModalityChanged(widget.modalityInput.copyWith(notes: val));
            },
          ),
        ],
      ),
    );
  }
}
