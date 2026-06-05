/// Step 2 widget for the replacement wizard — appointment checklist.
///
/// Displays affected appointments with checkboxes for selective swapping.
/// Includes a "Select All" toggle and a "Skip" escape hatch.
///
/// Rule 1 — dedicated sub-file to keep main screen compact.
/// Rule 2 — no Supabase calls; mutations via controller.
library;

import 'package:flutter/material.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/replacements/domain/replacement_repository.dart';
import 'package:spine_clinic_app/features/replacements/presentation/manage_replacement_controller.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';

/// Interactive checklist of appointments affected by the replacement.
class AffectedAppointmentsChecklist extends StatelessWidget {
  /// Creates an [AffectedAppointmentsChecklist].
  const AffectedAppointmentsChecklist({
    required this.state,
    required this.controller,
    required this.onSwapComplete,
    required this.onSkip,
    super.key,
  });

  /// Current wizard state.
  final ManageReplacementState state;

  /// Controller reference for mutations.
  final ManageReplacementController controller;

  /// Callback invoked after a successful bulk swap.
  final VoidCallback onSwapComplete;

  /// Callback invoked when the user chooses to skip manual swaps.
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final int totalCount = state.affectedAppointments.length;
    final bool allChecked =
        state.checkedAppointmentIds.length == totalCount && totalCount > 0;

    return Column(
      children: [
        // ── Header ──
        Padding(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Text(
            '${AppStrings.affectedAppointmentsHeader} ($totalCount)',
            style: AppTextStyles.headingSmall,
          ),
        ),

        // ── Empty state ──
        if (totalCount == 0)
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const EmptyState(
                  message: AppStrings.noAffectedAppointments,
                  icon: Icons.event_busy_rounded,
                ),
                const SizedBox(height: AppSizes.p24),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.p16,
                  ),
                  child: AppButton(
                    labelText: AppStrings.skipManualSwap,
                    variant: AppButtonVariant.secondary,
                    onPressed: onSkip,
                  ),
                ),
              ],
            ),
          )
        else ...[
          // ── Select All toggle ──
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.p16,
            ),
            child: SectionCard(
              title: AppStrings.selectAll,
              action: Switch.adaptive(
                value: allChecked,
                activeThumbColor: AppColors.primary,
                onChanged: (bool value) => controller.toggleAll(value),
              ),
              child: const SizedBox.shrink(),
            ),
          ),

          // ── Appointment list ──
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.p16,
                vertical: AppSizes.p8,
              ),
              itemCount: totalCount,
              itemBuilder: (BuildContext context, int index) {
                final AffectedAppointmentItem item =
                    state.affectedAppointments[index];
                final bool isChecked = state.checkedAppointmentIds
                    .contains(item.appointment.id);

                return _AppointmentCheckTile(
                  item: item,
                  isChecked: isChecked,
                  onToggle: () => controller.toggleAppointment(
                    item.appointment.id,
                  ),
                );
              },
            ),
          ),

          // ── Action buttons ──
          Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Column(
              children: [
                AppButton(
                  labelText: AppStrings.applyToSelected,
                  onPressed: state.checkedAppointmentIds.isEmpty ||
                          state.isSaving
                      ? null
                      : () async {
                          final bool success =
                              await controller.applyBulkSwap();
                          if (success) onSwapComplete();
                        },
                  isLoading: state.isSaving,
                ),
                const SizedBox(height: AppSizes.p12),
                AppButton(
                  labelText: AppStrings.skipManualSwap,
                  variant: AppButtonVariant.secondary,
                  onPressed: state.isSaving ? null : onSkip,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// A single appointment row with a checkbox for selection.
class _AppointmentCheckTile extends StatelessWidget {
  const _AppointmentCheckTile({
    required this.item,
    required this.isChecked,
    required this.onToggle,
  });

  final AffectedAppointmentItem item;
  final bool isChecked;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.p8),
      decoration: BoxDecoration(
        color: isChecked ? AppColors.primaryLight : AppColors.surface,
        border: Border.all(
          color: isChecked ? AppColors.primary : AppColors.border,
        ),
        borderRadius: AppSizes.borderRadiusCard,
      ),
      child: InkWell(
        borderRadius: AppSizes.borderRadiusCard,
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p12,
            vertical: AppSizes.p12,
          ),
          child: Row(
            children: [
              Checkbox(
                value: isChecked,
                activeColor: AppColors.primary,
                onChanged: (_) => onToggle(),
              ),
              const SizedBox(width: AppSizes.p8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.patientName,
                      style: AppTextStyles.bodyBold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSizes.p4),
                    Text(
                      Formatters.formatTime(
                        item.appointment.scheduledAt,
                      ),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
