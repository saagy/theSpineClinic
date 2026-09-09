import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_filter_sheet.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_sort_options.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_notes_sort_option.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_notes_list_notifier.dart';

abstract final class WorkspaceNoteFilters {
  static Future<void> show(BuildContext context, WidgetRef ref, String patientId) async {
    final initial = ref.read(patientNotesListProvider(patientId));
    final result = await AppointmentFilterSheet.show(
      context: context,
      dateFrom: initial.dateFrom,
      dateTo: initial.dateTo,
      doctorId: null,
      clinic: null,
      status: null,
      type: null,
      sort: initial.sort == PatientNotesSortOption.dateNewest
          ? AppointmentSortOption.dateDesc
          : AppointmentSortOption.dateAsc,
      canFilterDoctor: false,
      canFilterClinic: false,
      showAppointmentFilters: false,
    );
    if (result == null || !context.mounted) return;
    final notifier = ref.read(patientNotesListProvider(patientId).notifier);
    notifier.setDateRange(result.dateFrom, result.dateTo);
    notifier.setSort(
      result.sortOption == AppointmentSortOption.dateDesc
          ? PatientNotesSortOption.dateNewest
          : PatientNotesSortOption.dateOldest,
    );
  }
}
