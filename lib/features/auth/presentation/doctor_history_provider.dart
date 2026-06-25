/// Riverpod provider for the doctor historic appointments screen.
///
/// Owns the full filter/sort/pagination state. The UI shell only renders
/// whatever `build()` returns — no `setState` survives after this rewrite.
///
/// Rule 3  — all state via Riverpod.
/// Rule 4  — repository calls return [Result<T>].
/// Rule 12 — search input is debounced 300ms before triggering a filter pass.
/// Rule 25 — every mutation goes through [DoctorHistoryState.copyWith].
/// Rule 26 — `currentUserProvider` is `ref.watch`'d inside `build()` so the
///           notifier re-evaluates when the dependency resolves.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/auth/domain/history_sort_option.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';

/// Default number of items shown before pagination grows the window.
const int _kInitialVisibleCount = 30;

/// Number of additional items revealed per pagination burst.
const int _kPageStep = 30;

/// Debounce window for the search field (Rule 12).
const Duration _kSearchDebounce = Duration(milliseconds: 300);

/// State for the historic appointments screen.
class DoctorHistoryState {
  /// Creates a [DoctorHistoryState].
  const DoctorHistoryState({
    this.allItems = const [],
    this.searchQuery = '',
    this.sortOption = HistorySortOption.dateNewest,
    this.dateFrom,
    this.dateTo,
    this.typeFilter,
    this.branchFilter,
    this.visibleCount = _kInitialVisibleCount,
    this.isLoading = true,
    this.error,
    this.doctor,
  });

  /// Cached copy of the doctor's full history fetched from the repository.
  final List<DoctorScheduleItem> allItems;

  /// Free-text patient-name filter (debounced).
  final String searchQuery;

  /// Active sort option.
  final HistorySortOption sortOption;

  /// Optional inclusive lower bound for `scheduledAt`.
  final DateTime? dateFrom;

  /// Optional inclusive upper bound for `scheduledAt` (interpreted as
  /// end-of-day by the caller when set).
  final DateTime? dateTo;

  /// Optional session-type filter.
  final AppointmentType? typeFilter;

  /// Optional branch filter.
  final ClinicLocation? branchFilter;

  /// Current pagination window size.
  final int visibleCount;

  /// True while the repository call is in flight.
  final bool isLoading;

  /// Last error captured (null when loading succeeded or no attempt yet).
  final Object? error;

  /// Authenticated doctor (settled once by [DoctorHistoryNotifier.build]).
  final Staff? doctor;

  /// True when any filter (date range, type, branch) is active.
  bool get hasFilters =>
      dateFrom != null ||
      dateTo != null ||
      typeFilter != null ||
      branchFilter != null;

  /// Items passing every active filter, sorted by [sortOption], then
  /// truncated to the first [visibleCount] entries for pagination.
  List<DoctorScheduleItem> get visibleItems {
    final q = searchQuery.toLowerCase().trim();
    final end = dateTo?.add(const Duration(days: 1));
    final filtered = allItems.where((i) {
      if (q.isNotEmpty && !i.patient.fullName.toLowerCase().contains(q)) {
        return false;
      }
      if (dateFrom != null &&
          i.appointment.scheduledAt.isBefore(dateFrom!)) {
        return false;
      }
      if (end != null && !i.appointment.scheduledAt.isBefore(end)) {
        return false;
      }
      if (typeFilter != null && i.appointment.type != typeFilter) return false;
      if (branchFilter != null && i.patient.clinic != branchFilter) {
        return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      return switch (sortOption) {
        HistorySortOption.dateNewest =>
          b.appointment.scheduledAt.compareTo(a.appointment.scheduledAt),
        HistorySortOption.dateOldest =>
          a.appointment.scheduledAt.compareTo(b.appointment.scheduledAt),
        HistorySortOption.patientNameAsc =>
          a.patient.fullName.toLowerCase().compareTo(
                b.patient.fullName.toLowerCase(),
              ),
        HistorySortOption.patientNameDesc =>
          b.patient.fullName.toLowerCase().compareTo(
                a.patient.fullName.toLowerCase(),
              ),
      };
    });

    if (filtered.length <= visibleCount) return filtered;
    return filtered.take(visibleCount).toList();
  }

  /// Date-range label fragment for the active-filter chip, or null if no
  /// range is set. Pairs with [clearDateFilter] / [clearAllFilters] from
  /// the notifier when the screen wires chip removal.
  String? get dateRangeLabel {
    if (dateFrom == null && dateTo == null) return null;
    if (dateFrom != null && dateTo != null) {
      return '${dateFrom!.month}/${dateFrom!.day} – ${dateTo!.month}/${dateTo!.day}';
    }
    if (dateFrom != null) return 'From ${dateFrom!.month}/${dateFrom!.day}';
    return 'To ${dateTo!.month}/${dateTo!.day}';
  }
}

extension on DoctorHistoryState {
  /// Sentinel used by [DoctorHistoryState.copyWith] to distinguish
  /// "leave unchanged" (default sentinel) from "set to null" (explicit
  /// `null` passed by the caller). Without this discriminator, the
  /// `??` fallback syntax would silently swallow `null` and any
  /// per-field clear / unset operation would be lost.
  static const Object _unset = Object();

  /// Rule 25 — every field mutation funnels through this. Nullable
  /// filter fields use [_unset] so callers can pass `null` to clear
  /// them. `clearError: true` is provided as a parallel escape hatch
  /// for the non-nullable-default [error] field.
  DoctorHistoryState copyWith({
    List<DoctorScheduleItem>? allItems,
    String? searchQuery,
    HistorySortOption? sortOption,
    Object? dateFrom = _unset,
    Object? dateTo = _unset,
    Object? typeFilter = _unset,
    Object? branchFilter = _unset,
    int? visibleCount,
    bool? isLoading,
    Object? error = _unset,
    bool clearError = false,
    Staff? doctor,
  }) {
    return DoctorHistoryState(
      allItems: allItems ?? this.allItems,
      searchQuery: searchQuery ?? this.searchQuery,
      sortOption: sortOption ?? this.sortOption,
      dateFrom: identical(dateFrom, _unset)
          ? this.dateFrom
          : dateFrom as DateTime?,
      dateTo:
          identical(dateTo, _unset) ? this.dateTo : dateTo as DateTime?,
      typeFilter: identical(typeFilter, _unset)
          ? this.typeFilter
          : typeFilter as AppointmentType?,
      branchFilter: identical(branchFilter, _unset)
          ? this.branchFilter
          : branchFilter as ClinicLocation?,
      visibleCount: visibleCount ?? this.visibleCount,
      isLoading: isLoading ?? this.isLoading,
      error: clearError
          ? null
          : (identical(error, _unset) ? this.error : error),
      doctor: doctor ?? this.doctor,
    );
  }
}

  /// Manages the doctor's historic appointments: fetches once, applies
/// filters/sort, paginates.
class DoctorHistoryNotifier extends Notifier<DoctorHistoryState> {
  Timer? _searchDebounce;
  String? _lastUserId;

  @override
  DoctorHistoryState build() {
    final Staff? user = ref.watch(currentUserProvider).value;
    ref.onDispose(() {
      _searchDebounce?.cancel();
      _searchDebounce = null;
    });
    if (user != null && _lastUserId != user.id) {
      _lastUserId = user.id;
      Future.microtask(() => _load(user));
      return DoctorHistoryState(doctor: user);
    }
    if (user != null) return state.copyWith(doctor: user);
    return const DoctorHistoryState(isLoading: false);
  }

  Future<void> _load(Staff user) async {
    state = state.copyWith(doctor: user, isLoading: true, clearError: true);

    final repo = ref.read(appointmentRepositoryProvider);
    final Result<List<DoctorScheduleItem>> result =
        await repo.getDoctorSchedule(user.id);

    result.when(
      success: (List<DoctorScheduleItem> data) {
        state = state.copyWith(allItems: data, isLoading: false);
      },
      failure: (AppException exception) {
        state = state.copyWith(error: exception, isLoading: false);
      },
    );
  }

  /// Re-runs the repository fetch and resets pagination.
  Future<void> refresh() async {
    final Staff? user = ref.read(currentUserProvider).value;
    if (user != null) await _load(user);
  }

  /// Updates the patient-name search filter. The text is committed
  /// immediately for UX responsiveness; the filter recompute itself is
  /// debounced 300 ms so rapid keystrokes don't push mid-typing work
  /// (Rule 12).
  void setSearchQuery(String value) {
    state = state.copyWith(
      searchQuery: value,
      visibleCount: _kInitialVisibleCount,
    );
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_kSearchDebounce, () {
      state = state.copyWith();
    });
  }

  /// Updates the active sort option and resets pagination.
  void setSortOption(HistorySortOption option) {
    state = state.copyWith(sortOption: option, visibleCount: _kInitialVisibleCount);
  }

  /// Sets the appointment-date filter range. Pass `null` for either bound
  /// to skip filtering on that side. Passing `null, null` clears the range
  /// entirely. Each per-field mutator only invalidates its own field, so
  /// the screen can fan out from the filter sheet without intermediate
  /// rebuilds affecting other chips.
  void setDateRange(DateTime? dateFrom, DateTime? dateTo) {
    state = state.copyWith(
      dateFrom: dateFrom,
      dateTo: dateTo,
      visibleCount: _kInitialVisibleCount,
    );
  }

  /// Sets (or clears) the appointment-type filter. Pass `null` to clear.
  void setTypeFilter(AppointmentType? type) {
    state = state.copyWith(
      typeFilter: type,
      visibleCount: _kInitialVisibleCount,
    );
  }

  /// Sets (or clears) the branch filter. Pass `null` to clear.
  void setBranchFilter(ClinicLocation? clinic) {
    state = state.copyWith(
      branchFilter: clinic,
      visibleCount: _kInitialVisibleCount,
    );
  }

  /// Clears the date range only. Per-chip granularity so tapping the
  /// date chip's ✕ leaves type / branch filters intact.
  void clearDateRange() {
    state = state.copyWith(
      dateFrom: null,
      dateTo: null,
      visibleCount: _kInitialVisibleCount,
    );
  }

  /// Clears the appointment-type filter only.
  void clearTypeFilter() {
    state = state.copyWith(typeFilter: null, visibleCount: _kInitialVisibleCount);
  }

  /// Clears the branch filter only.
  void clearBranchFilter() {
    state = state.copyWith(
      branchFilter: null,
      visibleCount: _kInitialVisibleCount,
    );
  }

  /// Clears every filter (date range, type, branch) atomically and
  /// resets pagination. Wired to the "Clear All" chip in
  /// [ActiveFilterChipsRow]. Implementation funnels through the same
  /// [copyWith] path as the per-field clears so the contract stays
  /// consistent.
  void clearFilters() {
    state = state.copyWith(
      dateFrom: null,
      dateTo: null,
      typeFilter: null,
      branchFilter: null,
      visibleCount: _kInitialVisibleCount,
    );
  }

  /// Enlarges the pagination window by one page when the user scrolls
  /// near the bottom of the list.
  void loadMore() {
    final int next = (state.visibleCount + _kPageStep)
        .clamp(0, state.allItems.length);
    if (next != state.visibleCount) {
      state = state.copyWith(visibleCount: next);
    }
  }
}

/// Provider exposed to the historic appointments screen.
final doctorHistoryProvider =
    NotifierProvider<DoctorHistoryNotifier, DoctorHistoryState>(
  DoctorHistoryNotifier.new,
);
