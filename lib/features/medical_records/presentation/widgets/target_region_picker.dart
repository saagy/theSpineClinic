import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_target_region.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/target_region_picker_options.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/form_field_label.dart';

/// Adaptive target-region field with a searchable clinical selection surface.
class TargetRegionPicker extends StatelessWidget {
  const TargetRegionPicker({
    super.key,
    required this.label,
    required this.value,
    required this.regions,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<ModalityTargetRegion> regions;
  final ValueChanged<String> onChanged;

  Future<void> _selectRegion(BuildContext context) async {
    final String? selected =
        MediaQuery.sizeOf(context).width >= AppSizes.adaptiveModalBreakpoint
        ? await showDialog<String>(
            context: context,
            builder: (_) => _TargetRegionDialog(
              title: label,
              value: value,
              regions: regions,
            ),
          )
        : await AppBottomSheet.show<String>(
            context: context,
            title: label,
            initialChildSize: AppSizes.sheetInitialLarge,
            minChildSize: AppSizes.sheetInitialLarge,
            builder: (_, scrollController) => TargetRegionPickerOptions(
              value: value,
              regions: regions,
              scrollController: scrollController,
            ),
          );
    if (selected != null && selected != value) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return FormFieldLabel(
      label: label,
      child: Semantics(
        button: true,
        label: label,
        value: value,
        child: Material(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppSizes.r8),
          child: InkWell(
            onTap: regions.isEmpty ? null : () => _selectRegion(context),
            borderRadius: BorderRadius.circular(AppSizes.r8),
            child: Container(
              constraints: const BoxConstraints(
                minHeight: AppSizes.tappableMin,
              ),
              padding: AppSizes.paddingCell,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSizes.r8),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: cs.primary,
                    size: AppSizes.iconDefault,
                  ),
                  const SizedBox(width: AppSizes.p8),
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.p8),
                  Icon(Icons.unfold_more_rounded, color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TargetRegionDialog extends StatelessWidget {
  const _TargetRegionDialog({
    required this.title,
    required this.value,
    required this.regions,
  });

  final String title;
  final String value;
  final List<ModalityTargetRegion> regions;

  @override
  Widget build(BuildContext context) => Dialog(
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: AppSizes.targetRegionPickerWidth,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.headingSmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: AppStrings.close,
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: AppSizes.iconDefault,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.p12),
            TargetRegionPickerOptions(value: value, regions: regions),
          ],
        ),
      ),
    ),
  );
}
