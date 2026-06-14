/// Riverpod provider for the doctor schedule screen.
///
/// Fetches the logged-in doctor's full schedule, groups by date for the
/// week strip, and filters by selected day for the appointment list.
///
/// Rule 3 — all state via Riverpod.
/// Rule 4 — repository calls return [Result<T>].
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';

/// The full schedule state for the doctor schedule screen.
class DoctorScheduleState {
  const DoctorScheduleState({
    this.allItems = const [],
    this.selectedDate,
    this.loading = true,
    this.error,
    this.doctor,
  });

  final List<DoctorScheduleItem> allItems;
  final DateTime? selectedDate;
  final bool loading;
  final Object? error;
  final Staff? doctor;

  /// Items for the selected date, sorted: active by time asc, cancelled last.
  List<DoctorScheduleItem> get itemsForSelectedDay {
    if (selectedDate == null) return [];
    final day = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day);
    final nextDay = day.add(const Duration(days: 1));

    final matching = allItems.where((item) {
      final d = item.appointment.scheduledAt.toLocal();
      return !d.isBefore(day) && d.isBefore(nextDay);
    }).toList();

    final active = matching
        .where((i) => i.appointment.status != AppointmentStatus.cancelled)
        .toList()
      ..sort((a, b) => a.appointment.scheduledAt.compareTo(b.appointment.scheduledAt));

    final cancelled = matching
        .where((i) => i.appointment.status == AppointmentStatus.cancelled)
        .toList()
      ..sort((a, b) => a.appointment.scheduledAt.compareTo(b.appointment.scheduledAt));

    return [...active, ...cancelled];
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
    // Strip time components — compare calendar dates, not instants.
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: now.weekday % 7));
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
}

/// Manages the doctor's schedule: fetches all items, tracks selected day.
class DoctorScheduleNotifier extends Notifier<DoctorScheduleState> {
  bool _started = false;

  @override
  DoctorScheduleState build() {
    // Watch the auth provider so build() re-runs when the user resolves.
    final user = ref.watch(currentUserProvider).value;
    if (user != null && !_started) {
      _started = true;
      // Schedule the fetch after build completes so we don't mutate
      // state during the build phase.
      Future.microtask(() => _load(user));
    }
    return DoctorScheduleState(doctor: user);
  }

  Future<void> _load(Staff user) async {
    state = state.copyWith(doctor: user, loading: true);

    final repo = ref.read(appointmentRepositoryProvider);
    final result = await repo.getDoctorSchedule(user.id);

    result.when(
      success: (List<DoctorScheduleItem> data) {
        final today = DateTime.now();
        final selected = DateTime(today.year, today.month, today.day);
        state = state.copyWith(
          allItems: data,
          selectedDate: selected,
          loading: false,
        );
      },
      failure: (AppException exception) {
        state = state.copyWith(error: exception, loading: false);
      },
    );
  }

  void selectDate(DateTime date) {
    state = state.copyWith(
      selectedDate: DateTime(date.year, date.month, date.day),
    );
  }

  Future<void> refresh() async {
    final user = ref.read(currentUserProvider).value;
    if (user != null) _load(user);
  }
}

extension on DoctorScheduleState {
  DoctorScheduleState copyWith({
    List<DoctorScheduleItem>? allItems,
    DateTime? selectedDate,
    bool? loading,
    Object? error,
    bool clearError = false,
    Staff? doctor,
  }) {
    return DoctorScheduleState(
      allItems: allItems ?? this.allItems,
      selectedDate: selectedDate ?? this.selectedDate,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      doctor: doctor ?? this.doctor,
    );
  }
}

/// Provider for the doctor schedule.
final doctorScheduleProvider =
    NotifierProvider<DoctorScheduleNotifier, DoctorScheduleState>(
  DoctorScheduleNotifier.new,
);
