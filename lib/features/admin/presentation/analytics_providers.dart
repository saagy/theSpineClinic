import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/admin/data/analytics_dtos.dart';
import 'package:spine_clinic_app/features/admin/data/analytics_repository_impl.dart';
import 'package:spine_clinic_app/features/admin/domain/analytics_repository.dart';

/// Available time-range presets for the analytics dashboard.
enum AnalyticsTimeRange { today, thisWeek, thisMonth, lastMonth, yearToDate, custom }

/// Shared filter state driving all four analytics section providers.
class AnalyticsFilter {
  const AnalyticsFilter({
    required this.range,
    required this.resolvedNow,
    this.branchId,
    this.customStart,
    this.customEnd,
  });

  final AnalyticsTimeRange range;
  final DateTime resolvedNow;
  final String? branchId;
  final DateTime? customStart;
  final DateTime? customEnd;

  AnalyticsFilter copyWith({
    AnalyticsTimeRange? range,
    DateTime? resolvedNow,
    String? Function()? branchId,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    return AnalyticsFilter(
      range: range ?? this.range,
      resolvedNow: resolvedNow ?? this.resolvedNow,
      branchId: branchId != null ? branchId() : this.branchId,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
    );
  }
}

/// Resolves an [AnalyticsFilter] into a concrete [DateTimeRange].
/// Uses [filter.resolvedNow] so all four providers share the same frozen
/// "now" timestamp — no boundary drift between sections.
DateTimeRange _resolveRange(AnalyticsFilter filter) {
  final DateTime now = filter.resolvedNow;

  switch (filter.range) {
    case AnalyticsTimeRange.today:
      final DateTime start = DateTime(now.year, now.month, now.day);
      return DateTimeRange(start: start, end: start.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1)));
    case AnalyticsTimeRange.thisWeek:
      final int weekday = now.weekday;
      final DateTime start = DateTime(now.year, now.month, now.day).subtract(Duration(days: weekday - 1));
      return DateTimeRange(start: start, end: start.add(const Duration(days: 7)).subtract(const Duration(microseconds: 1)));
    case AnalyticsTimeRange.thisMonth:
      final DateTime start = DateTime(now.year, now.month, 1);
      return DateTimeRange(start: start, end: DateTime(now.year, now.month + 1, 1).subtract(const Duration(microseconds: 1)));
    case AnalyticsTimeRange.lastMonth:
      final DateTime start = DateTime(now.year, now.month - 1, 1);
      return DateTimeRange(start: start, end: DateTime(now.year, now.month, 1).subtract(const Duration(microseconds: 1)));
    case AnalyticsTimeRange.yearToDate:
      final DateTime start = DateTime(now.year, 1, 1);
      return DateTimeRange(start: start, end: DateTime(now.year, now.month + 1, 1).subtract(const Duration(microseconds: 1)));
    case AnalyticsTimeRange.custom:
      final DateTime start = filter.customStart ?? DateTime(now.year, now.month, now.day);
      final DateTime end = filter.customEnd ?? DateTime(now.year, now.month, now.day).add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));
      return DateTimeRange(start: start, end: end);
  }
}

/// Provides the [AnalyticsRepository] singleton.
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepositoryImpl(supabaseService: SupabaseService.instance);
});

/// Shared filter provider — drives all four analytics section providers.
final analyticsFilterProvider = NotifierProvider<AnalyticsFilterNotifier, AnalyticsFilter>(
  AnalyticsFilterNotifier.new,
);

/// Notifier managing the active analytics filter with 300ms debounce.
/// Range and branch debounce timers are independent so changing one
/// does not cancel a pending change to the other.
class AnalyticsFilterNotifier extends Notifier<AnalyticsFilter> {
  Timer? _rangeDebounce;
  Timer? _branchDebounce;

  @override
  AnalyticsFilter build() {
    ref.onDispose(() {
      _rangeDebounce?.cancel();
      _branchDebounce?.cancel();
    });
    return AnalyticsFilter(
      range: AnalyticsTimeRange.thisMonth,
      resolvedNow: DateTime.now(),
    );
  }

  void setRange(AnalyticsTimeRange range, {DateTime? start, DateTime? end}) {
    _rangeDebounce?.cancel();
    _rangeDebounce = Timer(const Duration(milliseconds: 300), () {
      state = state.copyWith(
        range: range,
        customStart: start,
        customEnd: end,
        resolvedNow: DateTime.now(),
      );
    });
  }

  void setBranch(String? branchId) {
    _branchDebounce?.cancel();
    _branchDebounce = Timer(const Duration(milliseconds: 300), () {
      state = state.copyWith(
        branchId: () => branchId,
        resolvedNow: DateTime.now(),
      );
    });
  }
}

// ── Independent section providers ──────────────────────────────

/// Financial summary provider — loads independently.
final financialSummaryProvider = FutureProvider<FinancialSummary>((ref) async {
  final filter = ref.watch(analyticsFilterProvider);
  final repo = ref.read(analyticsRepositoryProvider);
  final range = _resolveRange(filter);
  final result = await repo.getFinancialSummary(range: range, branchId: filter.branchId);
  return result.when(success: (d) => d, failure: (e) => throw e);
});

/// Appointment summary provider — loads independently.
final appointmentSummaryProvider = FutureProvider<AppointmentSummary>((ref) async {
  final filter = ref.watch(analyticsFilterProvider);
  final repo = ref.read(analyticsRepositoryProvider);
  final range = _resolveRange(filter);
  final result = await repo.getAppointmentSummary(range: range, branchId: filter.branchId);
  return result.when(success: (d) => d, failure: (e) => throw e);
});

/// Staff summary provider — loads independently.
final staffSummaryProvider = FutureProvider<StaffSummary>((ref) async {
  final filter = ref.watch(analyticsFilterProvider);
  final repo = ref.read(analyticsRepositoryProvider);
  final range = _resolveRange(filter);
  final result = await repo.getStaffSummary(range: range);
  return result.when(success: (d) => d, failure: (e) => throw e);
});

/// Patient summary provider — loads independently.
final patientSummaryProvider = FutureProvider<PatientSummary>((ref) async {
  final filter = ref.watch(analyticsFilterProvider);
  final repo = ref.read(analyticsRepositoryProvider);
  final range = _resolveRange(filter);
  final result = await repo.getPatientSummary(range: range, branchId: filter.branchId);
  return result.when(success: (d) => d, failure: (e) => throw e);
});
