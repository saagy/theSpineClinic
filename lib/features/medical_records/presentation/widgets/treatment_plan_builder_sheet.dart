library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/medical_records/domain/body_region.dart';
import 'package:spine_clinic_app/features/medical_records/domain/laterality.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_input.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_target_region.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_type.dart';
import 'package:spine_clinic_app/features/medical_records/domain/treatment_plan.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/treatment_plan_controller.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/modality_chip_selector.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/modality_config_card.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/treatment_plan_header_inputs.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';

/// Modal sheet for creating and modifying a treatment plan with modalities and regions.
class TreatmentPlanBuilderSheet extends ConsumerStatefulWidget {
  const TreatmentPlanBuilderSheet({
    super.key,
    required this.programId,
    required this.patientId,
    required this.affectedRegions,
    this.existingPlan,
    this.scrollController,
  });

  final String programId;
  final String patientId;
  final Set<BodyRegion> affectedRegions;
  final TreatmentPlan? existingPlan;
  final ScrollController? scrollController;

  static Future<TreatmentPlan?> show(
    BuildContext context, {
    required String programId,
    required String patientId,
    required Set<BodyRegion> affectedRegions,
    TreatmentPlan? existingPlan,
  }) =>
      AppBottomSheet.show<TreatmentPlan>(
        context: context,
        title: existingPlan != null ? AppStrings.editTreatmentPlan : AppStrings.newTreatmentPlan,
        initialChildSize: 0.85,
        minChildSize: 0.45,
        maxChildSize: AppSizes.sheetMax,
        builder: (ctx, scrollController) => TreatmentPlanBuilderSheet(
          programId: programId,
          patientId: patientId,
          affectedRegions: affectedRegions,
          existingPlan: existingPlan,
          scrollController: scrollController,
        ),
      );

  @override
  ConsumerState<TreatmentPlanBuilderSheet> createState() => _TreatmentPlanBuilderSheetState();
}

class _TreatmentPlanBuilderSheetState extends ConsumerState<TreatmentPlanBuilderSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  late bool _isActive;
  late final Map<ModalityType, ModalityInput> _modalityInputs;
  late final Set<ModalityType> _selectedModalities;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final plan = widget.existingPlan;
    _nameController = TextEditingController(text: plan?.planName ?? 'Plan 1');
    _notesController = TextEditingController(text: plan?.notes ?? '');
    _isActive = plan?.isActive ?? true;
    _modalityInputs = {for (final t in ModalityType.values) t: ModalityInput(modalityType: t)};
    _selectedModalities = {};

    if (plan != null) {
      for (final pm in plan.modalities) {
        _selectedModalities.add(pm.modalityType);
        _modalityInputs[pm.modalityType] = ModalityInput(
          modalityType: pm.modalityType,
          notes: pm.notes,
          regions: pm.regions.map((r) => RegionInput(targetRegion: r.targetRegion, laterality: r.laterality, timeMinutes: r.timeMinutes)).toList(),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final selectedList = _selectedModalities.map((type) => _modalityInputs[type]!).toList();

    final result = await ref.read(treatmentPlanControllerProvider.notifier).upsertPlan(
          programId: widget.programId,
          patientId: widget.patientId,
          planId: widget.existingPlan?.id,
          planName: _nameController.text.trim(),
          isActive: _isActive,
          notes: _notesController.text.trim(),
          modalities: selectedList,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.when(
      success: (plan) {
        AppSnackbar.show(context, message: AppStrings.treatmentPlanSaved, variant: AppSnackbarVariant.success);
        Navigator.of(context).pop(plan);
      },
      failure: (e) => AppSnackbar.show(context, message: AppStrings.fromKey(e.userMessageKey), variant: AppSnackbarVariant.error),
    );
  }

  void _handleToggle(ModalityType type, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedModalities.add(type);
        final current = _modalityInputs[type] ?? ModalityInput(modalityType: type);
        if (type.hasRegionSubSelections && current.regions.isEmpty) {
          final initial = _resolveSmartRegion(type);
          if (initial != null) {
            final isBilateral = ModalityTargetRegion.isRegionBilateral(type, initial);
            final target = initial == 'Paraspinal' ? 'Paraspinal (Cervical)' : initial;
            _modalityInputs[type] = current.copyWith(regions: [
              RegionInput(targetRegion: target, laterality: isBilateral ? Laterality.both : null, timeMinutes: 15),
            ]);
          }
        }
      } else {
        _selectedModalities.remove(type);
      }
    });
  }

  String? _resolveSmartRegion(ModalityType type) {
    final available = ModalityTargetRegion.regionsFor(type);
    if (available.isEmpty) return null;
    for (final bodyRegion in widget.affectedRegions) {
      final name = bodyRegion.displayName.toLowerCase();
      final match = available.where((r) => r.name.toLowerCase().contains(name) || name.contains(r.name.toLowerCase())).firstOrNull;
      if (match != null) return match.name;
    }
    return available.first.name;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
            children: [
              TreatmentPlanHeaderInputs(
                nameController: _nameController,
                notesController: _notesController,
                isActive: _isActive,
                onActiveChanged: (val) => setState(() => _isActive = val),
              ),
              const SizedBox(height: AppSizes.p16),
              Text(AppStrings.selectModalities, style: AppTextStyles.cardTitle.copyWith(color: cs.onSurface)),
              const SizedBox(height: AppSizes.p8),
              ModalityChipSelector(
                selectedModalities: _selectedModalities,
                onToggle: (type) => _handleToggle(type, !_selectedModalities.contains(type)),
              ),
              const SizedBox(height: AppSizes.p16),
              if (_selectedModalities.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSizes.p16),
                  decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(AppSizes.r16), border: Border.all(color: cs.outlineVariant)),
                  child: Text(AppStrings.noModalitiesSelected, textAlign: TextAlign.center, style: AppTextStyles.bodySecondary.copyWith(color: cs.onSurfaceVariant)),
                )
              else
                ...ModalityType.values.where(_selectedModalities.contains).map((type) => ModalityConfigCard(
                      key: ValueKey(type),
                      modalityType: type,
                      isSelected: true,
                      modalityInput: _modalityInputs[type]!,
                      onToggle: (sel) => _handleToggle(type, sel),
                      onRemove: () => _handleToggle(type, false),
                      onModalityChanged: (input) => setState(() => _modalityInputs[type] = input),
                    )),
              const SizedBox(height: AppSizes.p24),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(AppSizes.p16),
          decoration: BoxDecoration(color: cs.surface, border: Border(top: BorderSide(color: cs.outlineVariant))),
          child: AppButton(labelText: AppStrings.save, isLoading: _isSubmitting, onPressed: _submit),
        ),
      ],
    );
  }
}
