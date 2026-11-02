library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/domain/treatment_plan.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/treatment_plan_controller.dart';
import 'treatment_plan_summary.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/treatment_plan_builder_sheet.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/treatment_plan_history_tile.dart';
import 'package:spine_clinic_app/shared/widgets/record_action_menu.dart';
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
  bool? _historyExpanded;

  Future<void> _openPlanBuilder({TreatmentPlan? plan}) async {
    final user = ref.read(currentUserProvider).value;
    if (user?.isActive != true || user?.isSeniorDoctor != true) return;
    await TreatmentPlanBuilderSheet.show(
      context,
      programId: widget.program.id,
      patientId: widget.program.patientId,
      affectedRegions: widget.program.affectedRegions,
      existingPlan: plan,
      copyFromPlan: plan == null ? widget.program.activePlan : null,
      currentPlan: widget.program.activePlan,
    );
  }

  Future<void> _deletePlan(String planId) async {
    final user = ref.read(currentUserProvider).value;
    if (user?.isActive != true || user?.isSeniorDoctor != true) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => const ConfirmationDialog(
        title: AppStrings.deleteTreatmentPlan,
        message: AppStrings.deleteTreatmentPlanConfirm,
        isDestructive: true,
      ),
    );
    if (confirmed != true || !mounted) return;

    final res = await ref
        .read(treatmentPlanControllerProvider.notifier)
        .deletePlan(planId: planId, programId: widget.program.id, patientId: widget.program.patientId);
    if (!mounted) return;
    res.when(
      success: (_) =>
          AppSnackbar.show(context, message: AppStrings.treatmentPlanDeleted, variant: AppSnackbarVariant.success),
      failure: (e) =>
          AppSnackbar.show(context, message: AppStrings.fromKey(e.userMessageKey), variant: AppSnackbarVariant.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = ref.watch(currentUserProvider).value;
    final isSenior = user?.isActive == true && user?.isSeniorDoctor == true;
    final activePlan = widget.program.activePlan;
    final inactivePlans = widget.program.treatmentPlans.where((p) => p.id != activePlan?.id).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.p16),
      padding: const EdgeInsets.all(AppSizes.p20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSizes.r12),
        border: Border.all(color: cs.outlineVariant.withAlpha(90)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  AppStrings.currentTreatmentPlan,
                  style: AppTextStyles.headingSmall.copyWith(color: cs.onSurface),
                ),
              ),
              if (activePlan != null && isSenior)
                RecordActionMenu<String>(
                  tooltip: AppStrings.planActions,
                  actions: const [
                    RecordMenuAction('new_version', AppStrings.createTreatmentPlan, Icons.add),
                    RecordMenuAction('edit', AppStrings.editThisPlan, Icons.edit_outlined),
                    RecordMenuAction('delete', AppStrings.deleteThisPlan, Icons.delete_outline, destructive: true),
                  ],
                  onSelected: (action) {
                    if (action == 'new_version') _openPlanBuilder();
                    if (action == 'edit') _openPlanBuilder(plan: activePlan);
                    if (action == 'delete') _deletePlan(activePlan.id);
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSizes.p14),
          if (activePlan == null)
            Text(
              inactivePlans.isEmpty ? AppStrings.noTreatmentPlans : AppStrings.noActiveTreatmentPlan,
              style: AppTextStyles.body,
            )
          else
            TreatmentPlanSummary(plan: activePlan),
          if (activePlan == null && isSenior) ...[
            const SizedBox(height: AppSizes.p12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _openPlanBuilder(),
                style: TextButton.styleFrom(minimumSize: const Size(AppSizes.tappableMin, AppSizes.tappableMin)),
                icon: const Icon(Icons.add, size: AppSizes.iconSmall),
                label: const Text(AppStrings.newTreatmentPlan, style: AppTextStyles.bodyMedium),
              ),
            ),
          ],
          if (inactivePlans.isNotEmpty)
            _buildHistorySection(cs, inactivePlans, isSenior, isAutoExpanded: activePlan == null),
        ],
      ),
    );
  }

  Widget _buildHistorySection(ColorScheme cs, List<TreatmentPlan> plans, bool isSenior, {bool isAutoExpanded = false}) {
    final expanded = _historyExpanded ?? isAutoExpanded;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: AppSizes.p20, color: cs.outlineVariant.withAlpha(60)),
        InkWell(
          onTap: () => setState(() => _historyExpanded = !expanded),
          borderRadius: BorderRadius.circular(AppSizes.r8),
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSizes.tappableMin),
            padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${AppStrings.previousPlans} (${plans.length})',
                    style: AppTextStyles.bodyBold.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  size: AppSizes.iconSmall,
                  color: cs.onSurfaceVariant,
                ),
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
              currentPlanName: widget.program.activePlan?.planName,
              onEdit: () => _openPlanBuilder(plan: p),
              onDelete: () => _deletePlan(p.id),
            ),
        ],
      ],
    );
  }
}
