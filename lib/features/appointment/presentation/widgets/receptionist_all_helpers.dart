/// Date-grouped list builder and action helpers for the "All" appointments tab.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/all_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_filter_sheet.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_sort_options.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';

/// Opens the filter and sort bottom sheet for the All appointments tab.
Future<void> openAllFilterSheet(BuildContext context, WidgetRef ref) async {
  final notifier = ref.read(allAppointmentsProvider.notifier);
  final user = ref.read(currentUserProvider).value;
  final canFilterDoctor = user?.role == UserRole.receptionist ||
      (user?.role == UserRole.doctor && (user?.isSeniorDoctor ?? false)) ||
      user?.role == UserRole.superAdmin;
  final canFilterClinic = user?.role != UserRole.receptionist;

  ClinicLocation? clinicLoc;
  if (notifier.clinic != null) {
    clinicLoc = ClinicLocation.values
        .cast<ClinicLocation?>()
        .firstWhere((c) => c?.dbValue == notifier.clinic, orElse: () => null);
  }

  AppointmentStatus? status;
  if (notifier.status != null) {
    status = AppointmentStatus.values
        .cast<AppointmentStatus?>()
        .firstWhere((s) => s?.dbValue == notifier.status, orElse: () => null);
  }

  AppointmentType? type;
  if (notifier.type != null) {
    type = AppointmentType.values
        .cast<AppointmentType?>()
        .firstWhere((t) => t?.dbValue == notifier.type, orElse: () => null);
  }

  final result = await AppointmentFilterSheet.show(
    context: context,
    dateFrom: notifier.dateFrom,
    dateTo: notifier.dateTo,
    doctorId: notifier.doctorId,
    clinic: clinicLoc,
    status: status,
    type: type,
    sort: AppointmentSortOption.fromAscending(notifier.isAscending),
    canFilterDoctor: canFilterDoctor,
    canFilterClinic: canFilterClinic,
  );

  if (result != null) {
    notifier.applyFilters(
      from: result.dateFrom,
      to: result.dateTo,
      docId: result.doctorId,
      clinicLoc: result.clinic?.dbValue,
      statusFilter: result.status?.dbValue,
      typeFilter: result.type?.dbValue,
      ascending: result.sortOption.ascending,
    );
  }
}

/// Builds a date-grouped list from raw appointment items.
List<AllListItem> buildDateGroupedList(List<AppointmentWithPatient> items) {
  final result = <AllListItem>[];
  String? last;
  for (final item in items) {
    final d = item.appointment.scheduledAt.toLocal();
    final h = _header(d);
    if (h != last) {
      result.add(AllHeaderItem(h));
      last = h;
    }
    result.add(AllApptItem(item));
  }
  return result;
}

String _header(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final comp = DateTime(d.year, d.month, d.day);
  final diff = today.difference(comp).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff == -1) return 'Tomorrow';
  return DateFormat('EEEE, MMM d').format(d);
}

sealed class AllListItem {}

class AllHeaderItem extends AllListItem {
  AllHeaderItem(this.title);
  final String title;
}

class AllApptItem extends AllListItem {
  AllApptItem(this.item);
  final AppointmentWithPatient item;
}