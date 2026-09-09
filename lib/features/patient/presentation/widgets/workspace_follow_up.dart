import 'package:flutter/material.dart';
import 'package:spine_clinic_app/shared/widgets/record_action_menu.dart';
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
import 'package:spine_clinic_app/shared/widgets/record_section.dart';
import 'package:spine_clinic_app/shared/widgets/record_fact_grid.dart';

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
    final result = await ref
        .read(patientNextVisitControllerProvider.notifier)
        .setNextVisit(patient.id, selected);
    if (!context.mounted) return;
    result.when(
      success: (_) => AppSnackbar.show(context, message: AppStrings.nextVisitUpdated),
      failure: (e) => AppSnackbar.show(
        context,
        message: AppStrings.fromKey(e.userMessageKey),
        variant: AppSnackbarVariant.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = patientAppointmentsProvider(patient.id);
    final mutating = ref.watch(patientNextVisitControllerProvider).isMutating;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.zero,
      child: RecordFactGrid(
        children: [
          RecordAsync(
            value: ref.watch(provider),
            onRetry: () => ref.invalidate(provider),
            data: (appointments) {
              final upcoming =
                  appointments
                      .where(
                        (a) =>
                            a.status == AppointmentStatus.scheduled &&
                            !a.scheduledAt.isBefore(DateTime.now()),
                      )
                      .toList()
                    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
              if (upcoming.isEmpty) return const SizedBox.shrink();
              final Appointment appointment = upcoming.first;
              return Material(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppSizes.r8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppSizes.r8),
                  onTap: () async {
                    await context.push(AppRoutes.appointmentDetail.replaceFirst(':id', appointment.id));
                    if (context.mounted) ref.invalidate(provider);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.nextAppointment,
                          style: AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: AppSizes.p6),
                        Text(
                          Formatters.formatDateTime(appointment.scheduledAt),
                          style: AppTextStyles.bodyBold.copyWith(color: colors.onSurface),
                        ),
                        Text(
                          appointment.type.displayLabel,
                          style: AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.nextVisit,
                      style: AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                    ),
                    if (patient.nextVisitDate != null)
                      Text(
                        Formatters.formatDateMedium(patient.nextVisitDate!),
                        style: AppTextStyles.bodyBold,
                      ),
                  ],
                ),
              ),
              if (patient.nextVisitDate == null)
                IconButton(
                  tooltip: AppStrings.tapToSetNextVisit,
                  onPressed: mutating ? null : () => _setDate(context, ref),
                  icon: const Icon(Icons.add, size: AppSizes.iconDefault),
                )
              else
                RecordActionMenu<bool>(
                  tooltip: AppStrings.nextVisitOptions,
                  enabled: !mutating,
                  onSelected: (clear) => _setDate(context, ref, clear: clear),
                  actions: const [
                    RecordMenuAction(false, AppStrings.nextVisitChangeAction, Icons.edit_calendar_outlined),
                    RecordMenuAction(
                      true,
                      AppStrings.nextVisitClearAction,
                      Icons.event_busy_outlined,
                      destructive: true,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
