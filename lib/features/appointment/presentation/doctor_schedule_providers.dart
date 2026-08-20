/// Riverpod state for the doctor's pageable weekly schedule.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/doctor_schedule_state.dart';
import 'package:spine_clinic_app/features/appointment/presentation/schedule_week.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';

export 'doctor_schedule_state.dart';

class DoctorScheduleNotifier extends Notifier<DoctorScheduleState> {
  final Map<DateTime, List<AppointmentWithPatient>> _weekCache =
      <DateTime, List<AppointmentWithPatient>>{};
  String? _lastUserId;
  int _requestId = 0;

  @override
  DoctorScheduleState build() {
    final Staff? user = ref.watch(currentUserProvider).value;
    if (user != null && _lastUserId != user.id) {
      _lastUserId = user.id;
      _weekCache.clear();
      final DateTime today = ScheduleWeek.day(DateTime.now());
      Future<void>.microtask(() => _loadWeek(user, today, useCache: false));
      return DoctorScheduleState(doctor: user, selectedDate: today);
    }
    return user != null
        ? state.copyWith(doctor: user)
        : DoctorScheduleState(selectedDate: ScheduleWeek.day(DateTime.now()));
  }

  Future<void> _loadWeek(
    Staff user,
    DateTime date, {
    required bool useCache,
  }) async {
    final DateTime selected = ScheduleWeek.day(date);
    final DateTime weekStart = ScheduleWeek.start(selected);
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
    final AppointmentRepository repository = ref.read(
      appointmentRepositoryProvider,
    );
    final Result<List<AppointmentWithPatient>> result = await repository
        .getAllAppointments(
          dateFrom: ScheduleWeek.windowStart(selected),
          dateTo: ScheduleWeek.windowEnd(selected),
          doctorId: user.id,
          offset: 0,
          limit: 1000,
          ascending: true,
        );
    if (requestId != _requestId) return;

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

  void changeStatus(String appointmentId, AppointmentStatus newStatus) {
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
    final DateTime selected = state.selectedDate ?? DateTime.now();
    _weekCache[ScheduleWeek.start(selected)] = updated;
    state = state.copyWith(allItems: updated);
  }

  void selectDate(DateTime date) {
    final DateTime selected = ScheduleWeek.day(date);
    final DateTime? current = state.selectedDate;
    if (current != null && ScheduleWeek.same(current, selected)) {
      state = state.copyWith(selectedDate: selected);
      return;
    }
    final Staff? user = ref.read(currentUserProvider).value;
    if (user != null) {
      unawaited(_loadWeek(user, selected, useCache: true));
    }
  }

  void toggleShowCancelled() {
    state = state.copyWith(showCancelled: !state.showCancelled);
  }

  Future<void> refresh() async {
    final Staff? user = ref.read(currentUserProvider).value;
    if (user == null) return;
    await _loadWeek(
      user,
      state.selectedDate ?? DateTime.now(),
      useCache: false,
    );
  }
}

final doctorScheduleProvider =
    NotifierProvider<DoctorScheduleNotifier, DoctorScheduleState>(
      DoctorScheduleNotifier.new,
    );
