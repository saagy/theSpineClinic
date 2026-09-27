/// Riverpod state for the doctor's pageable weekly schedule.
library;

import 'dart:async';

import 'package:spine_clinic_app/features/appointment/domain/schedule_loader.dart';

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
    final DateTime today = ScheduleWeek.day(DateTime.now());
    final DoctorScheduleState next = _lastUserId == user?.id && user != null
        ? state.copyWith(
            doctor: user,
            allItems: const [],
            loading: true,
            clearError: true,
          )
        : DoctorScheduleState(doctor: user, selectedDate: today);
    _lastUserId = user?.id;
    _weekCache.clear();
    final int generation = ++_requestId;
    if (user != null) {
      Future<void>.microtask(() {
        if (ref.mounted && generation == _requestId) {
          unawaited(
            _loadWeek(user, next.selectedDate ?? today, useCache: false),
          );
        }
      });
    }
    return next;
  }

  Future<void> _loadWeek(
    Staff user,
    DateTime date, {
    required bool useCache,
  }) async {
    final DateTime selected = ScheduleWeek.day(date);
    final DateTime weekStart = ScheduleWeek.start(selected);
    final int requestId = ++_requestId;
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

    state = state.copyWith(
      allItems: const <AppointmentWithPatient>[],
      selectedDate: selected,
      loading: true,
      clearError: true,
    );
    final AppointmentRepository repository = ref.read(
      appointmentRepositoryProvider,
    );
    final Result<List<AppointmentWithPatient>> result = await repository
        .getScheduleAppointments(
          dateFrom: weekStart,
          dateTo: DateTime(weekStart.year, weekStart.month, weekStart.day + 7),
          doctorId: user.id,
        );
    if (!ref.mounted || requestId != _requestId) return;

    result.when(
      success: (List<AppointmentWithPatient> data) {
        _weekCache[weekStart] = data;
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
          (AppointmentWithPatient item) => item.appointment.id == appointmentId
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
    _weekCache.clear();
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
