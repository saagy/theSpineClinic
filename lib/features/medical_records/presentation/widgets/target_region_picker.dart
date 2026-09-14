import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_target_region.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/target_region_picker_options.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/form_field_label.dart';
import 'package:spine_clinic_app/shared/widgets/sheet_step_host.dart';

/// Opens the same searchable selection step at every window size.
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
    final SheetStepHostState? host = SheetStepHost.maybeOf(context);
    Widget options(
      ValueChanged<String> onSelected, [
      ScrollController? controller,
    ]) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
      child: TargetRegionPickerOptions(
        value: value,
        regions: regions,
        onSelected: onSelected,
        scrollController: controller,
      ),
    );
    final String? selected = host != null
        ? await host.showStep<String>(title: label, builder: options)
        : await AppBottomSheet.show<String>(
            context: context,
            title: label,
            initialChildSize: AppSizes.sheetInitialLarge,
            minChildSize: AppSizes.sheetInitialLarge,
            builder: (sheetContext, scrollController) => options(
              (value) => Navigator.of(sheetContext).pop(value),
              scrollController,
            ),
          );
    if (context.mounted && selected != null && selected != value) {
      onChanged(selected);
    }
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
                    Icons.accessibility_new_outlined,
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
