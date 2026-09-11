import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_next_visit_controller.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/record_action_menu.dart';
import 'package:spine_clinic_app/shared/widgets/record_section.dart';

class WorkspaceFollowUp extends ConsumerWidget {
  const WorkspaceFollowUp({super.key, required this.patient});
  final Patient patient;

  Future<void> _setDate(BuildContext context, WidgetRef ref, {bool clear = false}) async {
    if (ref.read(currentUserProvider).value?.isActive != true) return;
    DateTime? selected;
    if (clear) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => ConfirmationDialog(
          title: AppStrings.clearFollowUpTitle,
          message: AppStrings.clearFollowUpConfirmBody(patient.fullName),
          confirmLabel: AppStrings.nextVisitClearAction,
        ),
      );
      if (confirmed != true) return;
    } else {
      final now = DateTime.now();
      selected = await showDatePicker(
        context: context,
        initialDate: patient.nextVisitDate ?? now,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        helpText: AppStrings.nextVisit,
      );
      if (selected == null) return;
    }
    if (!context.mounted) return;
    final result = await ref.read(patientNextVisitControllerProvider.notifier).setNextVisit(patient.id, selected);
    if (!context.mounted) return;
    result.when(
      success: (_) => AppSnackbar.show(context, message: AppStrings.nextVisitUpdated),
      failure: (e) => AppSnackbar.show(context, message: AppStrings.fromKey(e.userMessageKey), variant: AppSnackbarVariant.error),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = patientAppointmentsProvider(patient.id);
    final mutating = ref.watch(patientNextVisitControllerProvider).isMutating;
    final cs = Theme.of(context).colorScheme;

    return RecordAsync(
      value: ref.watch(provider),
      onRetry: () => ref.invalidate(provider),
      data: (appointments) {
        final upcoming = appointments
            .where((a) => a.status == AppointmentStatus.scheduled && !a.scheduledAt.isBefore(DateTime.now()))
            .toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        final nextAppt = upcoming.isNotEmpty ? upcoming.first : null;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            final width = isWide ? (constraints.maxWidth - AppSizes.p12) / 2 : constraints.maxWidth;
            return Wrap(
              spacing: AppSizes.p12,
              runSpacing: AppSizes.p12,
              children: [
                if (nextAppt != null) SizedBox(width: width, child: _buildApptTile(context, ref, cs, nextAppt)),
                SizedBox(width: isWide && nextAppt != null ? width : constraints.maxWidth, child: _buildTargetTile(context, ref, cs, mutating)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildApptTile(BuildContext context, WidgetRef ref, ColorScheme cs, Appointment appt) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.p14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSizes.r12),
        border: Border.all(color: cs.outlineVariant.withAlpha(100)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.r8),
        onTap: () async {
          await context.push(AppRoutes.appointmentDetail.replaceFirst(':id', appt.id));
          if (context.mounted) ref.invalidate(patientAppointmentsProvider(patient.id));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.calendar, size: 14, color: cs.primary),
                const SizedBox(width: AppSizes.p6),
                Expanded(
                  child: Text(
                    AppStrings.confirmedNextAppointment,
                    style: AppTextStyles.captionBold.copyWith(color: cs.primary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.p8),
            Text(Formatters.formatDateTime(appt.scheduledAt), style: AppTextStyles.bodyBold.copyWith(color: cs.onSurface)),
            const SizedBox(height: AppSizes.p4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p6, vertical: AppSizes.p2),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(AppSizes.r4),
                border: Border.all(color: cs.outlineVariant.withAlpha(80)),
              ),
              child: Text(appt.type.displayLabel, style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetTile(BuildContext context, WidgetRef ref, ColorScheme cs, bool mutating) {
    final hasDate = patient.nextVisitDate != null;
    return Container(
      padding: const EdgeInsets.all(AppSizes.p14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSizes.r12),
        border: Border.all(color: cs.outlineVariant.withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(LucideIcons.clock, size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: AppSizes.p6),
                    Expanded(
                      child: Text(
                        AppStrings.nextVisitDate,
                        style: AppTextStyles.captionBold.copyWith(color: cs.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.p8),
              if (!hasDate)
                IconButton(
                  tooltip: AppStrings.tapToSetNextVisit,
                  onPressed: mutating ? null : () => _setDate(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                )
              else
                RecordActionMenu<bool>(
                  tooltip: AppStrings.nextVisitOptions,
                  enabled: !mutating,
                  onSelected: (clear) => _setDate(context, ref, clear: clear),
                  actions: const [
                    RecordMenuAction(false, AppStrings.nextVisitChangeAction, Icons.edit_calendar_outlined),
                    RecordMenuAction(true, AppStrings.nextVisitClearAction, Icons.event_busy_outlined, destructive: true),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppSizes.p8),
          Text(
            hasDate ? Formatters.formatDateMedium(patient.nextVisitDate!) : AppStrings.noNextVisitSet,
            style: hasDate ? AppTextStyles.bodyBold.copyWith(color: cs.onSurface) : AppTextStyles.body.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
