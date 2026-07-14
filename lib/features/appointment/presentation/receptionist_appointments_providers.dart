/// Riverpod providers for the receptionist appointments screen.
///
/// Manages today's and upcoming appointments with real-time status updates.
/// Supports admin branch override via [adminBranchFilterProvider].
///
/// Rule 3 — all state via Riverpod.
/// Rule 4 — repository calls return [Result<T>].
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/admin/presentation/branch_providers.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';

/// Holds the combined state for the receptionist appointments dashboard.
class ReceptionistAppointmentsState {
  const ReceptionistAppointmentsState({
    this.allItems = const [],
    this.selectedDate,
    this.loading = true,
    this.error,
    this.filterDoctorId,
  });

  final List<AppointmentWithPatient> allItems;
  final DateTime? selectedDate;
  final bool loading;
  final Object? error;
  final String? filterDoctorId;

  /// Items for the selected date in strict chronological order.
  List<AppointmentWithPatient> get itemsForSelectedDay {
    if (selectedDate == null) return [];
    final day = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day);
    final nextDay = day.add(const Duration(days: 1));

    final matching = allItems.where((item) {
      final d = item.appointment.scheduledAt.toLocal();
      return !d.isBefore(day) && d.isBefore(nextDay);
    }).toList()
      ..sort((a, b) => a.appointment.scheduledAt.compareTo(b.appointment.scheduledAt));

    return matching;
  }

  /// Whether today is the selected date.
  bool get isToday {
    if (selectedDate == null) return false;
    final now = DateTime.now();
    return selectedDate!.year == now.year &&
        selectedDate!.month == now.month &&
        selectedDate!.day == now.day;
  }

  /// Count of non-cancelled appointments for each day of the current week.
  Map<int, int> get dayAppointmentCounts {
    final counts = <int, int>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Week starts on Saturday: (weekday + 1) % 7 gives 0 for Saturday.
    final weekStart = today.subtract(Duration(days: (now.weekday + 1) % 7));
    for (int i = 0; i < 7; i++) {
      counts[i] = 0;
    }
    for (final item in allItems) {
      if (item.appointment.status == AppointmentStatus.cancelled) continue;
      final d = item.appointment.scheduledAt.toLocal();
      final dayOnly = DateTime(d.year, d.month, d.day);
      final diff = dayOnly.difference(weekStart).inDays;
      if (diff >= 0 && diff < 7) counts[diff] = (counts[diff] ?? 0) + 1;
    }
    return counts;
  }

  /// Returns a copy with the given fields replaced. Omitted fields keep their
  /// current value — never a constructor default.
  ReceptionistAppointmentsState copyWith({
    List<AppointmentWithPatient>? allItems,
    DateTime? selectedDate,
    bool? loading,
    Object? error,
    bool clearError = false,
    String? filterDoctorId,
    bool clearDoctorFilter = false,
  }) {
    return ReceptionistAppointmentsState(
      allItems: allItems ?? this.allItems,
      selectedDate: selectedDate ?? this.selectedDate,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      filterDoctorId: clearDoctorFilter ? null : (filterDoctorId ?? this.filterDoctorId),
    );
  }
}

/// Notifier managing appointments for the receptionist dashboard.
/// Loads the current week (from Saturday to Friday) and filters by selected date.
class ReceptionistAppointmentsNotifier
    extends Notifier<ReceptionistAppointmentsState> {
  @override
  ReceptionistAppointmentsState build() =>
      const ReceptionistAppointmentsState();

  AppointmentRepository get _repo => ref.read(appointmentRepositoryProvider);

  /// Returns the effective clinic filter.
  ClinicLocation? get _clinic {
    final user = ref.read(currentUserProvider).value;
    if (user?.role == UserRole.superAdmin) {
      final String? override = ref.read(adminBranchFilterProvider);
      if (override == null) return null; // All Branches
      if (override == 'tagamoa') return ClinicLocation.tagamoa;
      if (override == 'masr_elgedida') return ClinicLocation.masrElgedida;
    }
    return ref.read(activeBranchProvider);
  }

  /// Loads the entire week's appointments (Saturday to Friday) from the repository.
  Future<void> loadToday() async {
    state = state.copyWith(loading: true, clearError: true);
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Week starts on Saturday: (weekday + 1) % 7 gives 0 for Saturday.
    final weekStart = today.subtract(Duration(days: (now.weekday + 1) % 7));
    final weekEnd = weekStart.add(const Duration(days: 7)); // Next Saturday

    final Result<List<AppointmentWithPatient>> result = await _repo
        .getAllAppointments(
          dateFrom: weekStart,
          dateTo: weekEnd,
          doctorId: state.filterDoctorId,
          clinic: _clinic?.dbValue,
          offset: 0,
          limit: 1000,
          ascending: true,
        );

    result.when(
      success: (List<AppointmentWithPatient> data) {
        state = state.copyWith(
          allItems: data,
          selectedDate: state.selectedDate ?? today,
          loading: false,
        );
      },
      failure: (AppException exception) {
        state = state.copyWith(error: exception, loading: false);
      },
    );
  }

  /// Updates an appointment's status and immediately refreshes the local list.
  Future<void> changeStatus(
    String appointmentId,
    AppointmentStatus newStatus,
  ) async {
    final Result<void> result = await _repo.updateAppointmentStatus(
      appointmentId,
      newStatus,
    );

    result.when(
      success: (_) {
        final List<AppointmentWithPatient> updated = state.allItems.map((a) {
          if (a.appointment.id == appointmentId) {
            final Appointment updatedAppt = a.appointment.copyWith(
              status: newStatus,
            );
            return AppointmentWithPatient(
              appointment: updatedAppt,
              patient: a.patient,
            );
          }
          return a;
        }).toList();

        state = state.copyWith(allItems: updated);
      },
      failure: (AppException exception) {
        throw exception;
      },
    );
  }

  /// Sets the selected date in the week selector.
  void selectDate(DateTime date) {
    state = state.copyWith(
      selectedDate: DateTime(date.year, date.month, date.day),
    );
  }

  /// Sets or clears the doctor filter on the schedule.
  void setDoctorFilter(String? doctorId) {
    if (doctorId == null) {
      state = state.copyWith(clearDoctorFilter: true);
    } else {
      state = state.copyWith(filterDoctorId: doctorId);
    }
    loadToday();
  }
}

/// Provider for the receptionist appointments notifier.
final receptionistAppointmentsProvider =
    NotifierProvider<
      ReceptionistAppointmentsNotifier,
      ReceptionistAppointmentsState
    >(ReceptionistAppointmentsNotifier.new);
