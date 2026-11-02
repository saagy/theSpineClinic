import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/treatment_plan.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/treatment_plan_controller.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/record_action_menu.dart';
import 'treatment_modality_tile.dart';

class TreatmentPlanHistoryTile extends ConsumerStatefulWidget {
  const TreatmentPlanHistoryTile({
    super.key,
    required this.plan,
    required this.programId,
    required this.patientId,
    required this.isSeniorDoctor,
    required this.onEdit,
    required this.onDelete,
    this.currentPlanName,
  });
  final TreatmentPlan plan;
  final String programId;
  final String patientId;
  final bool isSeniorDoctor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String? currentPlanName;

  @override
  ConsumerState<TreatmentPlanHistoryTile> createState() => _TreatmentPlanHistoryTileState();
}

class _TreatmentPlanHistoryTileState extends ConsumerState<TreatmentPlanHistoryTile> {
  bool _isExpanded = false;
  bool _isActivating = false;

  Future<void> _activatePlan() async {
    final user = ref.read(currentUserProvider).value;
    if (_isActivating || user?.isActive != true || user?.isSeniorDoctor != true) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmationDialog(
        title: AppStrings.useThisPlan,
        message: AppStrings.usePlanConfirmation(widget.plan.planName, widget.currentPlanName),
        confirmLabel: AppStrings.useThisPlan,
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isActivating = true);
    final result = await ref
        .read(treatmentPlanControllerProvider.notifier)
        .activatePlan(planId: widget.plan.id, programId: widget.programId, patientId: widget.patientId);
    if (!mounted) return;
    setState(() => _isActivating = false);
    result.when(
      success: (_) => AppSnackbar.show(context, message: AppStrings.planActivated, variant: AppSnackbarVariant.success),
      failure: (e) =>
          AppSnackbar.show(context, message: AppStrings.fromKey(e.userMessageKey), variant: AppSnackbarVariant.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = ref.watch(currentUserProvider).value;
    final canEdit = widget.isSeniorDoctor && user?.isActive == true && user?.isSeniorDoctor == true;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  borderRadius: BorderRadius.circular(AppSizes.r8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: AppSizes.tappableMin),
                    child: Row(
                      children: [
                        Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more,
                          size: AppSizes.iconSmall,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSizes.p8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.plan.planName, style: AppTextStyles.bodyBold),
                              Text(
                                AppStrings.createdOn(Formatters.formatDateMedium(widget.plan.createdAt)),
                                style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (canEdit)
                RecordActionMenu<String>(
                  tooltip: AppStrings.planActions,
                  enabled: !_isActivating,
                  actions: const [
                    RecordMenuAction('edit', AppStrings.editThisPlan, Icons.edit_outlined),
                    RecordMenuAction('delete', AppStrings.deleteThisPlan, Icons.delete_outline, destructive: true),
                  ],
                  onSelected: (action) => action == 'edit' ? widget.onEdit() : widget.onDelete(),
                ),
            ],
          ),
          if (canEdit)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _isActivating ? null : _activatePlan,
                style: TextButton.styleFrom(minimumSize: const Size(AppSizes.tappableMin, AppSizes.tappableMin)),
                child: Text(
                  _isActivating ? AppStrings.savingClinicalRecord : AppStrings.useThisPlan,
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            ),
          if (_isExpanded) ...[
            if (widget.plan.notes?.trim().isNotEmpty == true)
              Text(widget.plan.notes!.trim(), style: AppTextStyles.bodySecondary),
            for (final modality in widget.plan.modalities) TreatmentModalityTile(modality: modality),
          ],
        ],
      ),
    );
  }
}
