/// Helper that builds [ActiveFilterChip] list from [AllAppointmentsNotifier] state.
///
/// Extracted to keep [ReceptionistAllTab] under the 200-line rule.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/all_appointments_providers.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';
import 'package:spine_clinic_app/shared/widgets/active_filter_chips_row.dart';

/// Builds active-filter chips reflecting the current notifier state.
List<ActiveFilterChip> buildAllFilterChips(WidgetRef ref) {
  final chips = <ActiveFilterChip>[];
  final n = ref.read(allAppointmentsProvider.notifier);
  final user = ref.watch(currentUserProvider).value;
  final bool isReceptionist = user?.role == UserRole.receptionist;

  if (n.dateFrom != null || n.dateTo != null) {
    String label;
    if (n.dateFrom != null && n.dateTo != null) {
      final to = n.dateTo!.subtract(const Duration(days: 1));
      label = '${Formatters.formatDateShort(n.dateFrom!)} – ${Formatters.formatDateShort(to)}';
    } else if (n.dateFrom != null) {
      label = 'From ${Formatters.formatDateShort(n.dateFrom!)}';
    } else {
      label = 'To ${Formatters.formatDateShort(n.dateTo!.subtract(const Duration(days: 1)))}';
    }
    chips.add(ActiveFilterChip(label: label, onRemove: () { n.setDateFrom(null); n.setDateTo(null); }));
  }
  if (n.doctorId != null) {
    final doctors = ref.watch(activeDoctorsProvider).value ?? [];
    final doctor = doctors.cast<Staff?>().firstWhere((d) => d!.id == n.doctorId, orElse: () => null);
    chips.add(ActiveFilterChip(label: doctor?.fullName ?? 'Doctor', onRemove: () => n.setDoctorFilter(null)));
  }
  if (n.clinic != null && !isReceptionist) {
    final c = ClinicLocation.values.cast<ClinicLocation?>().firstWhere((x) => x!.dbValue == n.clinic, orElse: () => null);
    chips.add(ActiveFilterChip(label: c?.displayLabel ?? n.clinic!, onRemove: () => n.setClinicFilter(null)));
  }
  if (n.status != null) {
    final s = AppointmentStatus.values.cast<AppointmentStatus?>().firstWhere((x) => x!.dbValue == n.status, orElse: () => null);
    chips.add(ActiveFilterChip(label: s?.displayLabel ?? n.status!, onRemove: () => n.setStatusFilter(null)));
  }
  if (n.type != null) {
    final t = AppointmentType.values.cast<AppointmentType?>().firstWhere((x) => x!.dbValue == n.type, orElse: () => null);
    chips.add(ActiveFilterChip(label: t?.displayLabel ?? n.type!, onRemove: () => n.setTypeFilter(null)));
  }
  return chips;
}
