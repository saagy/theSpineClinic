library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/medical_records/domain/treatment_plan.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/treatment_plan_controller.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/treatment_modality_tile.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';

/// Collapsible tile showing a historical/inactive treatment plan version.
class TreatmentPlanHistoryTile extends ConsumerStatefulWidget {
  const TreatmentPlanHistoryTile({
    super.key,
    required this.plan,
    required this.programId,
    required this.patientId,
    required this.isSeniorDoctor,
    required this.onEdit,
    required this.onDelete,
  });

  final TreatmentPlan plan;
  final String programId;
  final String patientId;
  final bool isSeniorDoctor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  ConsumerState<TreatmentPlanHistoryTile> createState() => _TreatmentPlanHistoryTileState();
}

class _TreatmentPlanHistoryTileState extends ConsumerState<TreatmentPlanHistoryTile> {
  bool _isExpanded = false;
  bool _isActivating = false;

  Future<void> _activatePlan() async {
    setState(() => _isActivating = true);
    final result = await ref.read(treatmentPlanControllerProvider.notifier).activatePlan(
          planId: widget.plan.id,
          programId: widget.programId,
          patientId: widget.patientId,
        );
    if (!mounted) return;
    setState(() => _isActivating = false);

    result.when(
      success: (_) => AppSnackbar.show(context, message: AppStrings.planActivated, variant: AppSnackbarVariant.success),
      failure: (e) => AppSnackbar.show(context, message: AppStrings.fromKey(e.userMessageKey), variant: AppSnackbarVariant.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.p10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(60),
        borderRadius: BorderRadius.circular(AppSizes.r12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(AppSizes.r12),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.p12),
              child: Row(
                children: [
                  Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: cs.onSurfaceVariant, size: 20),
                  const SizedBox(width: AppSizes.p8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.plan.planName, style: AppTextStyles.bodyBold.copyWith(color: cs.onSurface)),
                        const SizedBox(height: AppSizes.p2),
                        Text(
                          '${AppStrings.createdOn(Formatters.formatDateMedium(widget.plan.createdAt))} · ${AppStrings.modalitiesCount(widget.plan.modalities.length)}',
                          style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (widget.isSeniorDoctor) ...[
                    TextButton(
                      onPressed: _isActivating ? null : _activatePlan,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8, vertical: AppSizes.p4),
                      ),
                      child: _isActivating
                          ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary))
                          : Text(AppStrings.activate),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_horiz_rounded, size: AppSizes.iconDefault, color: cs.onSurfaceVariant),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: AppSizes.iconDefault,
                      color: cs.surface,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(AppSizes.r12)),
                      ),
                      elevation: 2,
                      position: PopupMenuPosition.under,
                      onSelected: (val) => val == 'edit' ? widget.onEdit() : widget.onDelete(),
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'edit',
                          height: AppSizes.buttonHeightSmall,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_outlined, color: cs.primary, size: AppSizes.iconSmall),
                              const SizedBox(width: AppSizes.p8),
                              Text(AppStrings.edit, style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          height: AppSizes.buttonHeightSmall,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.delete_outline_rounded, color: cs.error, size: AppSizes.iconSmall),
                              const SizedBox(width: AppSizes.p8),
                              Text(AppStrings.delete, style: AppTextStyles.bodyMedium.copyWith(color: cs.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSizes.p12, 0, AppSizes.p12, AppSizes.p12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: AppSizes.p8),
                  if (widget.plan.notes != null && widget.plan.notes!.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSizes.p4),
                    Text(widget.plan.notes!.trim(), style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(height: AppSizes.p8),
                  ],
                  ...widget.plan.modalities.map((m) => TreatmentModalityTile(modality: m)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
