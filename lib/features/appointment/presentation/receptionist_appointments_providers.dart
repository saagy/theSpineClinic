/// Riverpod state for the receptionist's pageable weekly schedule.
library;

import 'dart:async';

import 'schedule_freshness.dart';

import 'package:spine_clinic_app/features/appointment/domain/schedule_loader.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/admin/presentation/branch_providers.dart';
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

part 'receptionist_schedule_loading.dart';

class ReceptionistAppointmentsNotifier extends _ReceptionistScheduleBase {
  ReceptionistAppointmentsNotifier({super.now});

  @override
  ReceptionistAppointmentsState build() {
    final Staff? user = ref.watch(currentUserProvider).value;
    ref.watch(activeBranchProvider);
    ref.watch(adminBranchFilterProvider);
    final DateTime today = ScheduleWeek.day(DateTime.now());
    final ReceptionistAppointmentsState next =
        _lastUserId == user?.id && user != null
        ? state.copyWith(allItems: const [], loading: true, clearError: true)
        : ReceptionistAppointmentsState(selectedDate: today);
    _lastUserId = user?.id;
    _weekCache.clear();
    _freshness.clear();
    final int generation = ++_requestId;
    if (user != null) {
      Future<void>.microtask(() {
        if (ref.mounted && generation == _requestId) {
          unawaited(_loadWeek(next.selectedDate ?? today, useCache: false));
        }
      });
    }
    return next;
  }

  Future<void> loadToday() {
    _weekCache.clear();
    _freshness.clear();
    return _loadWeek(state.selectedDate ?? DateTime.now(), useCache: false);
  }

  void selectDate(DateTime date) {
    final DateTime selected = ScheduleWeek.day(date);
    final DateTime? current = state.selectedDate;
    if (current != null && ScheduleWeek.same(current, selected)) {
      state = state.copyWith(selectedDate: selected);
      return;
    }
    unawaited(_loadWeek(selected, useCache: true));
  }

  void changeStatus(String appointmentId, AppointmentStatus newStatus) {
    final List<AppointmentWithPatient> updated = state.allItems
        .map(
          (item) => item.appointment.id == appointmentId
              ? item.copyWith(
                  appointment: item.appointment.copyWith(status: newStatus),
                )
              : item,
        )
        .toList();
    _saveCurrentWeek(updated);
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
      state.allItems.map((item) {
        if (!ids.contains(item.appointment.id)) return item;
        return item.copyWith(
          appointment: item.appointment.copyWith(status: newStatus),
        );
      }).toList(),
    );
  }

  void _saveCurrentWeek(List<AppointmentWithPatient> items) {
    _freshness.revision++;
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
