import 'package:spine_clinic_app/features/patient/domain/patient_appointments_state.dart';
import 'package:spine_clinic_app/shared/widgets/search_filter_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_with_patient.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_agenda_row.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_appointments_notifier.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_appointment_chips_helper.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_appointment_tab_actions.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_appointment_filters.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_tab_header.dart';
import 'package:spine_clinic_app/shared/widgets/record_section.dart';
import 'package:spine_clinic_app/shared/widgets/record_skeleton.dart';

class WorkspaceAppointments extends ConsumerWidget {
  const WorkspaceAppointments({super.key, required this.patientId});
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(patientAppointmentsProvider(patientId));
    final notifier = ref.read(patientAppointmentsProvider(patientId).notifier);
    final chips = buildPatientAppointmentChips(ref, state, notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WorkspaceTabHeader(
          title: AppStrings.appointmentHistory,
          actionLabel: AppStrings.bookAppointment,
          onAction: () => PatientAppointmentTabActions.openNewAppointment(
            context: context,
            ref: ref,
            patientId: patientId,
          ),
        ),
        const SizedBox(height: AppSizes.p12),
        SearchFilterToolbar(
          query: state.searchQuery,
          hint: AppStrings.searchAppointmentTypes,
          onSearch: notifier.search,
          activeCount: chips.length,
          onFilter: () => WorkspaceAppointmentFilters.show(context, ref, patientId),
        ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: AppSizes.p10),
          Wrap(
            spacing: AppSizes.p8,
            runSpacing: AppSizes.p4,
            children: [
              for (final chip in chips)
                InputChip(label: Text(chip.label), onDeleted: chip.onRemove),
              TextButton(
                onPressed: notifier.clearFilters,
                child: const Text(AppStrings.clearFilters),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSizes.p14),
        RecordTransition(
          child: state.isLoading && state.appointments.isEmpty
              ? const RecordSkeleton(rows: 3)
              : _buildContent(context, ref, state, notifier),
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    PatientAppointmentsState state,
    PatientAppointments notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.errorMessage != null)
          Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: RecordMessage(
              message: AppStrings.patientSectionError,
              action: AppStrings.retry,
              onAction: () => notifier.refresh(silent: false),
            ),
          ),
        if (state.appointments.isEmpty && !state.isLoading && state.errorMessage == null)
          const Padding(
            padding: EdgeInsets.all(AppSizes.p24),
            child: RecordMessage(message: AppStrings.noAppointmentsFound),
          ),
        if (state.appointments.isNotEmpty) _AgendaRecords(items: state.appointments),
        if (state.hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
            child: TextButton(
              onPressed: state.isLoadingMore ? null : notifier.loadMore,
              child: const Text(AppStrings.showMoreRecords),
            ),
          ),
      ],
    );
  }
}

class _AgendaRecords extends StatelessWidget {
  const _AgendaRecords({required this.items});
  final List<AppointmentWithPatient> items;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (int i = 0; i < items.length; i++) ...[
        AppointmentAgendaRow(
          key: ValueKey(items[i].appointment.id),
          item: items[i],
          patientContext: true,
          showDate: true,
          showDoctor: true,
        ),
        if (i < items.length - 1) const Divider(height: AppSizes.borderWidth),
      ],
    ],
  );
}
