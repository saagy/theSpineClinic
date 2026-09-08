/// Riverpod providers for the all-appointments management screen.
///
/// Exposes [allAppointmentsProvider] — a notifier that fetches appointments
/// across all doctors and branches with combinable filters, desktop page
/// navigation, and mobile infinite-scroll pagination.
///
/// Rule 3 — all state via Riverpod.
/// Rule 4 — repository calls always return [Result<T>].
/// Rule 12 — patient search debounce is handled by [AppSearchBar] upstream.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/admin/presentation/branch_providers.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/all_appointments_filter_state.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';

export 'package:spine_clinic_app/features/appointment/presentation/all_appointments_filter_state.dart';

/// AsyncNotifier managing filtered, paginated appointment list for the
/// all-appointments screen.
///
/// Default filter state: current month, all doctors, all branches, all statuses.
/// Pagination: 30 items per page; page navigation on wide screens, infinite scroll on mobile.
final allAppointmentsProvider = AsyncNotifierProvider<AllAppointmentsNotifier,
    List<AppointmentWithPatient>>(AllAppointmentsNotifier.new);

/// Notifier holding filter state, pagination state, and re-fetching on every
/// filter or page change.
class AllAppointmentsNotifier
    extends AsyncNotifier<List<AppointmentWithPatient>> {
  DateTime? dateFrom;
  DateTime? dateTo;
  String? doctorId;
  String? clinic;
  String? status;
  String? type;

  String _patientQuery = '';
  bool _ascending = false;
  int _offset = 0;
  int _totalCount = 0;
  int _generation = 0;
  bool _loadingMore = false;
  static const int _pageSize = 30;

  /// The total count of appointments matching the current filters.
  int get totalCount => _totalCount;

  /// Fixed page size (30 items).
  int get pageSize => _pageSize;

  /// Current 1-based page number.
  int get currentPage => (_offset / _pageSize).floor() + 1;

  /// Total number of pages based on [_totalCount] and [_pageSize].
  int get totalPages => _totalCount <= 0
      ? 1
      : (_totalCount / _pageSize).ceil().clamp(1, 999999);

  /// Whether a previous page is available to navigate to.
  bool get hasPreviousPage => currentPage > 1;

  /// Whether a next page is available to navigate to.
  bool get hasNextPage =>
      _totalCount <= 0 ? false : _offset + _pageSize < _totalCount;

  /// Whether more pages are available to load via infinite scroll.
  bool get hasMore => (state.value?.length ?? 0) < _totalCount;

  void _setLoadingMore(bool v) {
    _loadingMore = v;
    ref.read(isLoadingMoreProvider.notifier).set(v);
  }

  @override
  Future<List<AppointmentWithPatient>> build() async {
    final DateTime now = DateTime.now();
    dateFrom = DateTime(now.year, now.month, 1);
    dateTo = DateTime(now.year, now.month + 1, 1);
    type = null;

    final user = ref.watch(currentUserProvider).value;
    if (user?.role == UserRole.receptionist) {
      final activeBranch = ref.watch(activeBranchProvider);
      clinic = activeBranch.dbValue;
    } else {
      clinic = null;
    }

    _offset = 0;
    return _fetch(_currentSnapshot());
  }

  FilterSnapshot _currentSnapshot() => FilterSnapshot(
        dateFrom: dateFrom,
        dateTo: dateTo,
        doctorId: doctorId,
        clinic: clinic,
        status: status,
        type: type,
        patientQuery: _patientQuery,
      );

  Future<List<AppointmentWithPatient>> _fetch(FilterSnapshot snap) async {
    final AppointmentRepository repo = ref.read(appointmentRepositoryProvider);
    final String? queryParam =
        snap.patientQuery.isEmpty ? null : snap.patientQuery;
    final Result<List<AppointmentWithPatient>> result =
        await repo.getAllAppointments(
      dateFrom: snap.dateFrom,
      dateTo: snap.dateTo,
      doctorId: snap.doctorId,
      clinic: snap.clinic,
      status: snap.status,
      type: snap.type,
      patientQuery: queryParam,
      offset: _offset,
      limit: _pageSize,
      ascending: _ascending,
    );

    // Fetch total count on first page or when uninitialized.
    if (_offset == 0 || _totalCount == 0) {
      final Result<int> countResult = await repo.countAllAppointments(
        dateFrom: snap.dateFrom,
        dateTo: snap.dateTo,
        doctorId: snap.doctorId,
        clinic: snap.clinic,
        status: snap.status,
        type: snap.type,
        patientQuery: queryParam,
      );
      countResult.when(
        success: (int count) => _totalCount = count,
        failure: (_) {
          // Count failed — fall back to optimistic pagination.
          _totalCount = _pageSize + 1;
        },
      );
    }

    return result.when(
      success: (List<AppointmentWithPatient> data) {
        if (data.length < _pageSize && _offset == 0) {
          _totalCount = data.length;
        } else if (data.length < _pageSize) {
          _totalCount = _offset + data.length;
        }
        final int expectedMin = _offset + data.length;
        if (_totalCount < expectedMin) {
          _totalCount = expectedMin;
        }
        return data;
      },
      failure: (AppException exception) => throw exception,
    );
  }

  /// Re-fetches from scratch. Snapshots filter values at call time so
  /// subsequent rapid filter changes cannot corrupt in-flight queries.
  void _reload({bool silent = false}) {
    final FilterSnapshot snap = _currentSnapshot();
    _generation++;
    final int gen = _generation;
    _offset = 0;
    _totalCount = 0;

    Future.delayed(const Duration(milliseconds: 150), () async {
      if (gen != _generation) return;
      _offset = 0;
      if (!silent && (!state.hasValue || (state.value?.isEmpty ?? true))) {
        state = const AsyncValue.loading();
      }
      try {
        final List<AppointmentWithPatient> data = await _fetch(snap);
        if (gen != _generation) return;
        state = AsyncValue.data(data);
      } catch (err, stack) {
        if (gen != _generation) return;
        state = AsyncValue.error(err, stack);
      }
    });
  }

  /// Navigates directly to [page] (1-based) replacing the current items with
  /// that single page's appointments. Used on wide/desktop screens.
  Future<void> goToPage(int page) async {
    if (page < 1 || page > totalPages) return;
    final int targetOffset = (page - 1) * _pageSize;
    if (_offset == targetOffset && state.hasValue) return;
    _offset = targetOffset;
    _generation++;
    final int gen = _generation;
    final FilterSnapshot snap = _currentSnapshot();
    state = const AsyncValue.loading();
    try {
      final List<AppointmentWithPatient> data = await _fetch(snap);
      if (gen != _generation) return;
      state = AsyncValue.data(data);
    } catch (err, stack) {
      if (gen != _generation) return;
      state = AsyncValue.error(err, stack);
    }
  }

  /// Navigates to the next page.
  Future<void> nextPage() => goToPage(currentPage + 1);

  /// Navigates to the previous page.
  Future<void> previousPage() => goToPage(currentPage - 1);

  /// Appends the next page of results to the current list. Used for mobile infinite scroll.
  Future<void> loadMore() async {
    if (!hasMore || _loadingMore) return;
    _setLoadingMore(true);
    final FilterSnapshot snap = _currentSnapshot();
    final List<AppointmentWithPatient> current =
        List<AppointmentWithPatient>.from(state.value ?? []);
    _offset += _pageSize;
    try {
      final List<AppointmentWithPatient> newItems = await _fetch(snap);
      state = AsyncValue.data([...current, ...newItems]);
    } catch (err, stack) {
      _offset -= _pageSize;
      state = AsyncValue.error(err, stack);
    } finally {
      _setLoadingMore(false);
    }
  }

  void updateStatus(String appointmentId, AppointmentStatus newStatus) {
    if (!state.hasValue) return;
    final List<AppointmentWithPatient> current = state.value!;
    final List<AppointmentWithPatient> updated = current
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
    state = AsyncValue.data(updated);
  }

  /// Refreshes the list while preserving all current filter settings.
  void refresh() => _reload(silent: true);

  void setDateFrom(DateTime? d) { dateFrom = d; _reload(); }
  void setDateTo(DateTime? d) { dateTo = d; _reload(); }
  void setDoctorFilter(String? id) { doctorId = id; _reload(); }
  void setClinicFilter(String? c) { clinic = c; _reload(); }
  void setStatusFilter(String? s) { status = s; _reload(); }
  void setTypeFilter(String? t) { type = t; _reload(); }
  void setSortAscending(bool asc) { _ascending = asc; _reload(); }
  bool get isAscending => _ascending;

  /// Counts the currently active filtering constraints.
  int get activeFiltersCount {
    int count = 0;
    if (dateFrom != null || dateTo != null) count++;
    if (doctorId != null) count++;
    final user = ref.read(currentUserProvider).value;
    if (clinic != null && user?.role != UserRole.receptionist) count++;
    if (status != null) count++;
    if (type != null) count++;
    return count;
  }

  /// Atomically applies new filter parameters and optional sort order.
  void applyFilters({
    required DateTime? from,
    required DateTime? to,
    required String? docId,
    required String? clinicLoc,
    required String? statusFilter,
    required String? typeFilter,
    bool? ascending,
  }) {
    dateFrom = from;
    dateTo = to;
    doctorId = docId;

    final user = ref.read(currentUserProvider).value;
    if (user?.role == UserRole.receptionist) {
      clinic = ref.read(activeBranchProvider).dbValue;
    } else {
      clinic = clinicLoc;
    }

    status = statusFilter;
    type = typeFilter;
    if (ascending != null) {
      _ascending = ascending;
    }
    _reload();
  }

  void setFilters({
    required DateTime? from,
    required DateTime? to,
    required String? docId,
    required String? clinicLoc,
    required String? statusFilter,
    required String? typeFilter,
  }) {
    applyFilters(
      from: from,
      to: to,
      docId: docId,
      clinicLoc: clinicLoc,
      statusFilter: statusFilter,
      typeFilter: typeFilter,
    );
  }

  void searchPatient(String query) {
    _patientQuery = query;
    _reload();
  }

  void clearAll() {
    dateFrom = null;
    dateTo = null;
    doctorId = null;

    final user = ref.read(currentUserProvider).value;
    if (user?.role == UserRole.receptionist) {
      clinic = ref.read(activeBranchProvider).dbValue;
    } else {
      clinic = null;
    }

    status = null;
    type = null;
    _patientQuery = '';
    _reload();
  }
}
