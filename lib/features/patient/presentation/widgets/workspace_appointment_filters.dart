import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_filter_sheet.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_filter_chips_section.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_sort_options.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_appointment_sort_option.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_appointments_notifier.dart';
import 'package:spine_clinic_app/shared/widgets/filter_option_chip.dart';

abstract final class WorkspaceAppointmentFilters {
  static Future<void> show(BuildContext context, WidgetRef ref, String patientId) async {
    final initial = ref.read(patientAppointmentsProvider(patientId));
    final statuses = {...?initial.statusFilter};
    final types = {...?initial.typeFilter};
    bool? package = initial.usePackageFilter;
    final result = await AppointmentFilterSheet.show(
      context: context,
      dateFrom: initial.dateFrom,
      dateTo: initial.dateTo,
      doctorId: initial.doctorId,
      clinic: null,
      status: null,
      type: null,
      sort: initial.sort == PatientAppointmentSortOption.dateNewest
          ? AppointmentSortOption.dateDesc
          : AppointmentSortOption.dateAsc,
      canFilterDoctor: true,
      canFilterClinic: false,
      onResetAdditional: () {
        statuses.clear();
        types.clear();
        package = null;
      },
      appointmentFiltersBuilder: (_) => StatefulBuilder(
        builder: (context, update) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppointmentFilterChipsSection(
              selectedClinic: null,
              selectedStatus: null,
              selectedType: null,
              canFilterClinic: false,
              onClinicChanged: (_) {},
              selectedStatuses: statuses,
              selectedTypes: types,
              onStatusChanged: (value) => update(() {
                if (value == null) {
                  statuses.clear();
                } else {
                  statuses.contains(value) ? statuses.remove(value) : statuses.add(value);
                }
              }),
              onTypeChanged: (value) => update(() {
                if (value == null) {
                  types.clear();
                } else {
                  types.contains(value) ? types.remove(value) : types.add(value);
                }
              }),
            ),
            const SizedBox(height: AppSizes.p20),
            Wrap(
              spacing: AppSizes.p8,
              runSpacing: AppSizes.p8,
              children: [
                for (final value in <bool?>[null, true, false])
                  FilterOptionChip(
                    label: value == null
                        ? AppStrings.packageFilterAll
                        : value
                        ? AppStrings.packageFilterPackage
                        : AppStrings.packageFilterNoPackage,
                    isSelected: package == value,
                    onTap: () => update(() => package = value),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
    if (result == null || !context.mounted) return;
    final notifier = ref.read(patientAppointmentsProvider(patientId).notifier);
    notifier.setDoctorFilter(result.doctorId);
    notifier.setDateRange(result.dateFrom, result.dateTo);
    notifier.setStatusFilter(statuses.isEmpty ? null : statuses);
    notifier.setTypeFilter(types.isEmpty ? null : types);
    notifier.setUsePackageFilter(package);
    notifier.setSort(
      result.sortOption == AppointmentSortOption.dateDesc
          ? PatientAppointmentSortOption.dateNewest
          : PatientAppointmentSortOption.dateOldest,
    );
  }
}
