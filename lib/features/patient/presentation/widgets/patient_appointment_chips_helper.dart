/// Active-filter-chips helper for [PatientTabAppointments].
///
/// Extracted to keep the parent file under 200 lines.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';
import 'package:spine_clinic_app/shared/widgets/active_filter_chips_row.dart';

/// Builds active filter chips from the appointments notifier state.
List<ActiveFilterChip> buildPatientAppointmentChips(
  WidgetRef ref,
  dynamic state,
  dynamic notifier,
) {
  final chips = <ActiveFilterChip>[];
  if (state.dateFrom != null || state.dateTo != null) {
    final label = state.dateFrom != null && state.dateTo != null
        ? '${Formatters.formatDateShort(state.dateFrom!)} – ${Formatters.formatDateShort(state.dateTo!.subtract(const Duration(days: 1)))}'
        : state.dateFrom != null
            ? 'From ${Formatters.formatDateShort(state.dateFrom!)}'
            : 'To ${Formatters.formatDateShort(state.dateTo!.subtract(const Duration(days: 1)))}';
    chips.add(ActiveFilterChip(
        label: label, onRemove: () => notifier.setDateRange(null, null)));
  }
  if (state.statusFilter != null && state.statusFilter!.isNotEmpty) {
    chips.add(ActiveFilterChip(
        label: 'Status (${state.statusFilter!.length})',
        onRemove: () => notifier.setStatusFilter(null)));
  }
  if (state.typeFilter != null && state.typeFilter!.isNotEmpty) {
    chips.add(ActiveFilterChip(
        label: 'Type (${state.typeFilter!.length})',
        onRemove: () => notifier.setTypeFilter(null)));
  }
  if (state.doctorId != null) {
    final doctors = ref.watch(allDoctorsForFilterProvider).value ?? [];
    final doctor = doctors
        .cast<Staff?>()
        .firstWhere((d) => d!.id == state.doctorId, orElse: () => null);
    chips.add(ActiveFilterChip(
        label: doctor?.fullName ?? AppStrings.unknownDoctorFallback,
        onRemove: () => notifier.setDoctorFilter(null)));
  }
  if (state.usePackageFilter != null) {
    chips.add(ActiveFilterChip(
      label: state.usePackageFilter!
          ? AppStrings.packageFilterPackage
          : AppStrings.packageFilterNoPackage,
      onRemove: () => notifier.setUsePackageFilter(null),
    ));
  }
  return chips;
}
