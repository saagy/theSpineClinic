import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';

import 'package:spine_clinic_app/features/appointment/domain/appointment_with_patient.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_agenda_row.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_appointments_notifier.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_appointment_tab_actions.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_appointment_chips_helper.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_appointment_filters.dart';
import 'package:spine_clinic_app/shared/widgets/record_section.dart';
import 'package:spine_clinic_app/shared/widgets/record_skeleton.dart';
import 'package:spine_clinic_app/shared/widgets/record_filter_sheet.dart';

class WorkspaceAppointments extends ConsumerWidget {
  const WorkspaceAppointments({super.key, required this.patientId});
  final String patientId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(patientAppointmentsProvider(patientId));
    final notifier = ref.read(patientAppointmentsProvider(patientId).notifier);
    final chips = buildPatientAppointmentChips(ref, state, notifier);
    return RecordSection(
      showTitle: false,
      trailing: RecordFilterButton(
        compact: true,
        onPressed: () => WorkspaceAppointmentFilters.show(context, ref, patientId),
      ),
      title: AppStrings.appointmentHistory,
      action: AppStrings.bookAppointment,
      primaryAction: true,
      onAction: () =>
          PatientAppointmentTabActions.openNewAppointment(context: context, ref: ref, patientId: patientId),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (chips.isNotEmpty)
            Wrap(
              spacing: AppSizes.p8,
              runSpacing: AppSizes.p4,
              children: [
                for (final chip in chips) InputChip(label: Text(chip.label), onDeleted: chip.onRemove),
                TextButton(onPressed: notifier.clearFilters, child: const Text(AppStrings.clearFilters)),
              ],
            ),
          if (chips.isNotEmpty) const SizedBox(height: AppSizes.p8),
          RecordTransition(
            child: state.isLoading && state.appointments.isEmpty
                ? const RecordSkeleton(rows: 3)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (state.errorMessage != null)
                        RecordMessage(
                          message: AppStrings.patientSectionError,
                          action: AppStrings.retry,
                          onAction: () => notifier.refresh(silent: false),
                        ),
                      if (state.appointments.isEmpty && !state.isLoading && state.errorMessage == null)
                        const RecordMessage(message: AppStrings.noAppointmentsFound),
                      _AgendaRecords(
                        items: state.appointments,
                        onChanged: () => ref.invalidate(patientAppointmentsProvider(patientId)),
                      ),
                      if (state.hasMore)
                        TextButton(
                          onPressed: state.isLoadingMore ? null : notifier.loadMore,
                          child: const Text(AppStrings.showMoreRecords),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _AgendaRecords extends StatelessWidget {
  const _AgendaRecords({required this.items, required this.onChanged});
  final List<AppointmentWithPatient> items;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (int i = 0; i < items.length; i++) ...[
        AppointmentAgendaRow(
          item: items[i],
          patientContext: true,
          showDate: true,
          showDoctor: false,
          onStatusChanged: onChanged,
        ),
        const Divider(height: AppSizes.borderWidth),
      ],
    ],
  );
}
