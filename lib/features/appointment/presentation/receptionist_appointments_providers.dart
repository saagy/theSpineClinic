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
    this.today = const [],
    this.upcoming = const [],
    this.todayLoading = true,
    this.upcomingLoading = true,
    this.todayError,
    this.upcomingError,
  });

  final List<AppointmentWithPatient> today;
  final List<AppointmentWithPatient> upcoming;
  final bool todayLoading;
  final bool upcomingLoading;
  final Object? todayError;
  final Object? upcomingError;

  int get scheduledCount =>
      today.where((a) => a.appointment.status == AppointmentStatus.scheduled).length;

  int get checkedInCount =>
      today.where((a) => a.appointment.status == AppointmentStatus.checkedIn).length;

  int get cancelledCount =>
      today.where((a) => a.appointment.status == AppointmentStatus.cancelled).length;

  /// Returns a copy with the given fields replaced. Omitted fields keep their
  /// current value — never a constructor default.
  ReceptionistAppointmentsState copyWith({
    List<AppointmentWithPatient>? today,
    List<AppointmentWithPatient>? upcoming,
    bool? todayLoading,
    bool? upcomingLoading,
    Object? todayError,
    bool clearTodayError = false,
    Object? upcomingError,
    bool clearUpcomingError = false,
  }) {
    return ReceptionistAppointmentsState(
      today: today ?? this.today,
      upcoming: upcoming ?? this.upcoming,
      todayLoading: todayLoading ?? this.todayLoading,
      upcomingLoading: upcomingLoading ?? this.upcomingLoading,
      todayError: clearTodayError ? null : (todayError ?? this.todayError),
      upcomingError: clearUpcomingError ? null : (upcomingError ?? this.upcomingError),
    );
  }
}

/// Notifier managing today's and upcoming appointment lists for the receptionist
/// dashboard. Handles status transitions with immediate optimistic updates.
class ReceptionistAppointmentsNotifier
    extends Notifier<ReceptionistAppointmentsState> {
  @override
  ReceptionistAppointmentsState build() => const ReceptionistAppointmentsState();

  AppointmentRepository get _repo =>
      ref.read(appointmentRepositoryProvider);

  /// Returns the effective clinic filter.
  ///
  /// For admin users, respects [adminBranchFilterProvider]:
  /// - `null` → "All Branches" (no clinic filter)
  /// - a dbValue string → filters to that specific branch
  /// For non-admin users, uses the active branch as-is.
  ClinicLocation? get _clinic {
    final user = ref.read(currentUserProvider).value;
    if (user?.role == UserRole.superAdmin) {
      final String? override = ref.read(adminBranchFilterProvider);
      if (override == null) return null; // All Branches
      // Map dbValue back to enum
      if (override == 'tagamoa') return ClinicLocation.tagamoa;
      if (override == 'masr_elgedida') return ClinicLocation.masrElgedida;
    }
    return ref.read(activeBranchProvider);
  }

  /// Loads today's appointments from the repository.
  Future<void> loadToday() async {
    state = state.copyWith(todayLoading: true, clearTodayError: true);

    final Result<List<AppointmentWithPatient>> result =
        await _repo.getTodayAppointmentsWithPatients(_clinic);

    result.when(
      success: (List<AppointmentWithPatient> data) {
        state = state.copyWith(today: data, todayLoading: false);
      },
      failure: (AppException exception) {
        state = state.copyWith(
          todayError: exception,
          todayLoading: false,
        );
      },
    );
  }

  /// Loads upcoming (future) appointments from the repository.
  Future<void> loadUpcoming() async {
    state = state.copyWith(upcomingLoading: true, clearUpcomingError: true);

    final Result<List<AppointmentWithPatient>> result =
        await _repo.getUpcomingAppointmentsWithPatients(_clinic);

    result.when(
      success: (List<AppointmentWithPatient> data) {
        state = state.copyWith(upcoming: data, upcomingLoading: false);
      },
      failure: (AppException exception) {
        state = state.copyWith(
          upcomingError: exception,
          upcomingLoading: false,
        );
      },
    );
  }

  /// Updates an appointment's status and immediately refreshes the local list.
  Future<void> changeStatus(
    String appointmentId,
    AppointmentStatus newStatus,
  ) async {
    final Result<void> result =
        await _repo.updateAppointmentStatus(appointmentId, newStatus);

    result.when(
      success: (_) {
        final List<AppointmentWithPatient> updated =
            state.today.map((a) {
          if (a.appointment.id == appointmentId) {
            final Appointment updatedAppt =
                a.appointment.copyWith(status: newStatus);
            return AppointmentWithPatient(
              appointment: updatedAppt,
              patient: a.patient,
            );
          }
          return a;
        }).toList();

        state = state.copyWith(today: updated);
      },
      failure: (AppException exception) {
        throw exception;
      },
    );
  }
}

/// Provider for the receptionist appointments notifier.
final receptionistAppointmentsProvider =
    NotifierProvider<ReceptionistAppointmentsNotifier, ReceptionistAppointmentsState>(
  ReceptionistAppointmentsNotifier.new,
);
