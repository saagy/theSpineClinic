/// Riverpod state for the receptionist's pageable weekly schedule.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/admin/presentation/branch_providers.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_state.dart';
import 'package:spine_clinic_app/features/appointment/presentation/schedule_week.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';

export 'receptionist_appointments_state.dart';

class ReceptionistAppointmentsNotifier
    extends Notifier<ReceptionistAppointmentsState> {
  final Map<DateTime, List<AppointmentWithPatient>> _weekCache =
      <DateTime, List<AppointmentWithPatient>>{};
  String? _cacheScope;
  String? _lastUserId;
  int _requestId = 0;

  @override
  ReceptionistAppointmentsState build() {
    final Staff? user = ref.watch(currentUserProvider).value;
    final DateTime today = ScheduleWeek.day(DateTime.now());
    if (user != null && _lastUserId != user.id) {
      _lastUserId = user.id;
      _weekCache.clear();
      Future<void>.microtask(() => _loadWeek(today, useCache: false));
      return ReceptionistAppointmentsState(selectedDate: today);
    }
    return user != null
        ? state
        : ReceptionistAppointmentsState(selectedDate: today);
  }

  AppointmentRepository get _repository =>
      ref.read(appointmentRepositoryProvider);

  ClinicLocation? get _clinic {
    final Staff? user = ref.read(currentUserProvider).value;
    if (user?.role == UserRole.superAdmin) {
      final String? override = ref.read(adminBranchFilterProvider);
      if (override == null) return null;
      if (override == 'tagamoa') return ClinicLocation.tagamoa;
      if (override == 'masr_elgedida') return ClinicLocation.masrElgedida;
    }
    return ref.read(activeBranchProvider);
  }

  Future<void> _loadWeek(DateTime date, {required bool useCache}) async {
    final Staff? user = ref.read(currentUserProvider).value;
    if (user == null) return;
    final DateTime selected = ScheduleWeek.day(date);
    final DateTime weekStart = ScheduleWeek.start(selected);
    final ClinicLocation? clinic = _clinic;
    final String scope =
        '${user.id}|${state.filterDoctorId}|${clinic?.dbValue ?? 'all'}';
    if (_cacheScope != scope) {
      _cacheScope = scope;
      _weekCache.clear();
    }

    final List<AppointmentWithPatient>? cached = _weekCache[weekStart];
    if (useCache && cached != null) {
      state = state.copyWith(
        allItems: cached,
        selectedDate: selected,
        loading: false,
        clearError: true,
      );
      return;
    }

    final int requestId = ++_requestId;
    final bool hasExisting = state.allItems.isNotEmpty;
    if (!hasExisting) {
      state = state.copyWith(
        allItems: const <AppointmentWithPatient>[],
        selectedDate: selected,
        loading: true,
        clearError: true,
      );
    } else {
      state = state.copyWith(selectedDate: selected, clearError: true);
    }
    final Result<List<AppointmentWithPatient>> result = await _repository
        .getAllAppointments(
          dateFrom: ScheduleWeek.windowStart(selected),
          dateTo: ScheduleWeek.windowEnd(selected),
          doctorId: state.filterDoctorId,
          clinic: clinic?.dbValue,
          offset: 0,
          limit: 1000,
          ascending: true,
        );
    if (!ref.mounted || requestId != _requestId) return;

    result.when(
      success: (List<AppointmentWithPatient> data) {
        _weekCache.addAll(
          ScheduleWeek.groupWindow<AppointmentWithPatient>(
            data,
            around: selected,
            dateOf: (AppointmentWithPatient item) =>
                item.appointment.scheduledAt.toLocal(),
          ),
        );
        state = state.copyWith(
          allItems: _weekCache[weekStart] ?? <AppointmentWithPatient>[],
          selectedDate: selected,
          loading: false,
          clearError: true,
        );
      },
      failure: (AppException exception) {
        state = state.copyWith(error: exception, loading: false);
      },
    );
  }

  Future<void> loadToday() =>
      _loadWeek(state.selectedDate ?? DateTime.now(), useCache: false);

  void selectDate(DateTime date) {
    final DateTime selected = ScheduleWeek.day(date);
    final DateTime? current = state.selectedDate;
    if (current != null && ScheduleWeek.same(current, selected)) {
      state = state.copyWith(selectedDate: selected);
      return;
    }
    unawaited(_loadWeek(selected, useCache: true));
  }

  Future<void> changeStatus(
    String appointmentId,
    AppointmentStatus newStatus,
  ) async {
    final Result<void> result = await _repository.updateAppointmentStatus(
      appointmentId,
      newStatus,
    );
    result.when(
      success: (_) {
        final List<AppointmentWithPatient> updated = state.allItems
            .map(
              (AppointmentWithPatient item) =>
                  item.appointment.id == appointmentId
                  ? AppointmentWithPatient(
                      appointment: item.appointment.copyWith(status: newStatus),
                      patient: item.patient,
                    )
                  : item,
            )
            .toList();
        _saveCurrentWeek(updated);
      },
      failure: (AppException exception) => throw exception,
    );
  }

  Future<void> changeGroupStatus(
    List<String> appointmentIds,
    AppointmentStatus newStatus,
  ) async {
    final Set<String> ids = appointmentIds.toSet();
    for (final String id in appointmentIds) {
      final Result<void> result = await _repository.updateAppointmentStatus(
        id,
        newStatus,
      );
      result.when(
        success: (_) {},
        failure: (AppException exception) => throw exception,
      );
    }
    _saveCurrentWeek(
      state.allItems.map((AppointmentWithPatient item) {
        if (!ids.contains(item.appointment.id)) return item;
        final Appointment appointment = item.appointment.copyWith(
          status: newStatus,
        );
        return AppointmentWithPatient(
          appointment: appointment,
          patient: item.patient,
        );
      }).toList(),
    );
  }

  void _saveCurrentWeek(List<AppointmentWithPatient> items) {
    final DateTime selected = state.selectedDate ?? DateTime.now();
    _weekCache[ScheduleWeek.start(selected)] = items;
    state = state.copyWith(allItems: items);
  }

  void setDoctorFilter(String? doctorId) {
    state = doctorId == null
        ? state.copyWith(clearDoctorFilter: true)
        : state.copyWith(filterDoctorId: doctorId);
    unawaited(loadToday());
  }

  void toggleShowCancelled() {
    state = state.copyWith(showCancelled: !state.showCancelled);
  }
}

final receptionistAppointmentsProvider =
    NotifierProvider<
      ReceptionistAppointmentsNotifier,
      ReceptionistAppointmentsState
    >(ReceptionistAppointmentsNotifier.new);
