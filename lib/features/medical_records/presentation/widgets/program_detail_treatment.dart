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
import 'package:spine_clinic_app/shared/widgets/record_section.dart';
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

  Future<void> _openPlanBuilder({TreatmentPlan? plan}) => TreatmentPlanBuilderSheet.show(
    context,
    programId: widget.program.id,
    patientId: widget.program.patientId,
    affectedRegions: widget.program.affectedRegions,
    existingPlan: plan,
  );

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
      success: (_) => AppSnackbar.show(
        context,
        message: AppStrings.treatmentPlanDeleted,
        variant: AppSnackbarVariant.success,
      ),
      failure: (e) => AppSnackbar.show(
        context,
        message: AppStrings.fromKey(e.userMessageKey),
        variant: AppSnackbarVariant.error,
      ),
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
    return RecordSection(
      title: AppStrings.treatmentPlan,
      action: activePlan == null && isSenior ? AppStrings.newTreatmentPlan : null,
      primaryAction: true,
      onAction: () => _openPlanBuilder(),
      trailing: activePlan != null && isSenior
          ? RecordActionMenu<String>(
              actions: const [
                RecordMenuAction('new_version', AppStrings.newPlanVersion, Icons.add),
                RecordMenuAction('edit', AppStrings.edit, Icons.edit_outlined),
                RecordMenuAction('delete', AppStrings.delete, Icons.delete_outline, destructive: true),
              ],
              onSelected: (action) {
                final user = ref.read(currentUserProvider).value;
                if (user?.isActive != true || user?.isSeniorDoctor != true) return;
                if (action == 'new_version') _openPlanBuilder();
                if (action == 'edit') _openPlanBuilder(plan: activePlan);
                if (action == 'delete') _deletePlan(activePlan.id);
              },
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (activePlan == null)
            RecordMessage(message: inactivePlans.isEmpty ? AppStrings.noTreatmentPlans : AppStrings.noActiveTreatmentPlan)
          else
            _buildActivePlan(cs, activePlan),
          if (inactivePlans.isNotEmpty)
            _buildHistorySection(cs, inactivePlans, isSenior, isAutoExpanded: activePlan == null),
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
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(AppSizes.r999),
              ),
              child: Text(
                plan.planName,
                style: AppTextStyles.captionBold.copyWith(color: cs.onPrimaryContainer),
              ),
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
        for (int i = 0; i < plan.modalities.length; i++)
          TreatmentModalityTile(modality: plan.modalities[i], showDivider: i < plan.modalities.length - 1),
      ],
    );
  }

  Widget _buildHistorySection(
    ColorScheme cs,
    List<TreatmentPlan> plans,
    bool isSenior, {
    bool isAutoExpanded = false,
  }) {
    final expanded = _historyExpanded ?? isAutoExpanded;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: AppSizes.p16, color: cs.outlineVariant.withAlpha(60)),
        InkWell(
          onTap: () => setState(() => _historyExpanded = !expanded),
          borderRadius: BorderRadius.circular(AppSizes.r8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.p12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${AppStrings.previousPlans} (${plans.length})',
                  style: AppTextStyles.captionBold.copyWith(color: cs.onSurfaceVariant),
                ),
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
