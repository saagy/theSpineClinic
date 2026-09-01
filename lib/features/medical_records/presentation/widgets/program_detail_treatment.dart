library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_target_region.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/domain/treatment_plan.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/treatment_plan_controller.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/treatment_modality_tile.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/treatment_plan_builder_sheet.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/treatment_plan_history_tile.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';

/// Card component presenting active and historical treatment plans in a program.
class ProgramDetailTreatment extends ConsumerStatefulWidget {
  const ProgramDetailTreatment({super.key, required this.program});
  final PatientProgram program;

  @override
  ConsumerState<ProgramDetailTreatment> createState() => _ProgramDetailTreatmentState();
}

class _ProgramDetailTreatmentState extends ConsumerState<ProgramDetailTreatment> {
  bool _historyExpanded = false;

  Future<void> _openPlanBuilder({TreatmentPlan? plan}) => TreatmentPlanBuilderSheet.show(context, programId: widget.program.id, patientId: widget.program.patientId, affectedRegions: widget.program.affectedRegions, existingPlan: plan);

  Future<void> _deletePlan(String planId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => const ConfirmationDialog(title: AppStrings.deleteTreatmentPlan, message: AppStrings.deleteTreatmentPlanConfirm, isDestructive: true),
    );
    if (confirmed != true || !mounted) return;

    final res = await ref.read(treatmentPlanControllerProvider.notifier).deletePlan(planId: planId, programId: widget.program.id, patientId: widget.program.patientId);
    if (!mounted) return;
    res.when(
      success: (_) => AppSnackbar.show(context, message: AppStrings.treatmentPlanDeleted, variant: AppSnackbarVariant.success),
      failure: (e) => AppSnackbar.show(context, message: AppStrings.fromKey(e.userMessageKey), variant: AppSnackbarVariant.error),
    );
  }

  PopupMenuItem<String> _menuItem(String val, IconData icon, Color iconColor, String label, {Color? textColor}) => PopupMenuItem(
        value: val,
        height: AppSizes.buttonHeightSmall,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSizes.iconSmall, color: iconColor),
            const SizedBox(width: AppSizes.p8),
            Text(label, style: AppTextStyles.bodyMedium.copyWith(color: textColor)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSenior = ref.watch(currentUserProvider).value?.isSeniorDoctor ?? false;
    final activePlan = widget.program.activePlan;
    final inactivePlans = widget.program.treatmentPlans.where((p) => p.id != activePlan?.id).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Container(
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(AppSizes.r16), border: Border.all(color: cs.outlineVariant)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medical_services_outlined, size: AppSizes.iconSmall, color: cs.primary),
              const SizedBox(width: AppSizes.p8),
              Expanded(child: Text(AppStrings.treatmentPlan, style: AppTextStyles.cardTitle.copyWith(color: cs.onSurface), overflow: TextOverflow.ellipsis)),
              if (activePlan != null && isSenior)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz_rounded, color: cs.onSurfaceVariant, size: AppSizes.iconDefault),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: AppSizes.iconDefault,
                  color: cs.surface,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppSizes.r12))),
                  elevation: 2,
                  position: PopupMenuPosition.under,
                  tooltip: AppStrings.treatmentPlan,
                  onSelected: (val) {
                    if (val == 'new_version') _openPlanBuilder();
                    if (val == 'edit') _openPlanBuilder(plan: activePlan);
                    if (val == 'delete') _deletePlan(activePlan.id);
                  },
                  itemBuilder: (ctx) => [
                    _menuItem('new_version', Icons.add_circle_outline, cs.primary, AppStrings.newPlanVersion, textColor: cs.onSurface),
                    _menuItem('edit', Icons.edit_outlined, cs.primary, AppStrings.edit, textColor: cs.onSurface),
                    _menuItem('delete', Icons.delete_outline_rounded, cs.error, AppStrings.delete, textColor: cs.error),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppSizes.p12),
          if (activePlan == null) ...[
            Text(inactivePlans.isNotEmpty ? AppStrings.noActiveTreatmentPlan : AppStrings.noTreatmentPlans, style: AppTextStyles.bodySecondary.copyWith(color: cs.onSurfaceVariant)),
            if (isSenior) ...[
              const SizedBox(height: AppSizes.p12),
              AppButton(labelText: AppStrings.newTreatmentPlan, icon: Icons.add_circle_outline, variant: AppButtonVariant.secondary, shape: AppButtonShape.pill, onPressed: () => _openPlanBuilder()),
            ],
          ] else
            _buildActivePlan(cs, activePlan),
          if (inactivePlans.isNotEmpty) ...[
            const SizedBox(height: AppSizes.p12),
            _buildHistorySection(cs, inactivePlans, isSenior, isAutoExpanded: activePlan == null),
          ],
        ],
      ),
    );
  }

  Widget _buildActivePlan(ColorScheme cs, TreatmentPlan plan) {
    final totalMin = plan.modalities.fold<int>(
      0,
      (sum, m) =>
          sum +
          m.regions
              .where((r) => ModalityTargetRegion.hasDuration(m.modalityType, r.targetRegion))
              .fold<int>(0, (rSum, r) => rSum + r.timeMinutes),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSizes.p8,
          runSpacing: AppSizes.p4,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8, vertical: AppSizes.p2),
              decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(AppSizes.r999)),
              child: Text(plan.planName, style: AppTextStyles.captionBold.copyWith(color: cs.onPrimaryContainer)),
            ),
            Text(
              '${AppStrings.createdOn(Formatters.formatDateMedium(plan.createdAt))} · ${AppStrings.modalitiesCount(plan.modalities.length)}${totalMin > 0 ? ' · ${AppStrings.totalDurationFormat(totalMin)}' : ''}',
              style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
        if (plan.notes != null && plan.notes!.trim().isNotEmpty) ...[
          const SizedBox(height: AppSizes.p8),
          Text(plan.notes!.trim(), style: AppTextStyles.bodySecondary.copyWith(color: cs.onSurfaceVariant)),
        ],
        const SizedBox(height: AppSizes.p8),
        for (int i = 0; i < plan.modalities.length; i++) TreatmentModalityTile(modality: plan.modalities[i], showDivider: i < plan.modalities.length - 1),
      ],
    );
  }

  Widget _buildHistorySection(ColorScheme cs, List<TreatmentPlan> plans, bool isSenior, {bool isAutoExpanded = false}) {
    final expanded = _historyExpanded || isAutoExpanded;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: AppSizes.p16, color: cs.outlineVariant.withAlpha(60)),
        InkWell(
          onTap: () => setState(() => _historyExpanded = !expanded),
          borderRadius: BorderRadius.circular(AppSizes.r8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.p4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${AppStrings.previousPlans} (${plans.length})', style: AppTextStyles.captionBold.copyWith(color: cs.onSurfaceVariant)),
                Icon(expanded ? Icons.expand_less : Icons.expand_more, size: 18, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
        if (expanded) ...[
          const SizedBox(height: AppSizes.p8),
          for (final p in plans)
            TreatmentPlanHistoryTile(
              plan: p,
              programId: widget.program.id,
              patientId: widget.program.patientId,
              isSeniorDoctor: isSenior,
              onEdit: () => _openPlanBuilder(plan: p),
              onDelete: () => _deletePlan(p.id),
            ),
        ],
      ],
    );
  }
}
