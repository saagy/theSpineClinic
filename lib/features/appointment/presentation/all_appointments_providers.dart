/// Riverpod providers for the all-appointments management screen.
///
/// Exposes [allAppointmentsProvider] — a notifier that fetches appointments
/// across all doctors and branches with combinable filters and infinite-scroll
/// pagination.
///
/// Rule 3 — all state via Riverpod.
/// Rule 4 — repository calls always return [Result<T>].
/// Rule 12 — patient search debounce is handled by [AppSearchBar] upstream.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/admin/presentation/branch_providers.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';

/// AsyncNotifier managing filtered, paginated appointment list for the
/// all-appointments screen.
///
/// Default filter state: current month, all doctors, all branches, all statuses.
/// Pagination: 30 items per page, infinite scroll via [loadMore].
final allAppointmentsProvider = AsyncNotifierProvider<AllAppointmentsNotifier,
    List<AppointmentWithPatient>>(AllAppointmentsNotifier.new);

/// Whether a load-more fetch is in flight — watched by the UI to show a
/// bottom-of-list spinner.
final isLoadingMoreProvider = NotifierProvider<IsLoadingMoreNotifier, bool>(
  IsLoadingMoreNotifier.new,
);

class IsLoadingMoreNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool v) => state = v;
}

/// Immutable snapshot of all filter parameters captured at reload time
/// so in-flight queries cannot be corrupted by a subsequent filter change.
class _FilterSnapshot {
  const _FilterSnapshot({
    required this.dateFrom,
    required this.dateTo,
    required this.doctorId,
    required this.clinic,
    required this.status,
    required this.type,
    required this.patientQuery,
  });

  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? doctorId;
  final String? clinic;
  final String? status;
  final String? type;
  final String patientQuery;
}

/// Notifier holding filter state, pagination state, and re-fetching on every
/// filter change.
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

  /// Whether more pages are available to load.
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

    return _fetch(_currentSnapshot());
  }

  _FilterSnapshot _currentSnapshot() => _FilterSnapshot(
        dateFrom: dateFrom,
        dateTo: dateTo,
        doctorId: doctorId,
        clinic: clinic,
        status: status,
        type: type,
        patientQuery: _patientQuery,
      );

  Future<List<AppointmentWithPatient>> _fetch(_FilterSnapshot snap) async {
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

    // Fetch total count on first page.
    if (_offset == 0) {
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
        if (data.length < _pageSize) {
          _totalCount = _offset + data.length;
        }
        // Defensive: guard against transient count < data mismatch
        // during Supabase replication lag after status changes.
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
  ///
  /// Includes a 150 ms defensive debounce to let Supabase replication
  /// settle after write operations (check-in / cancel). Existing data
  /// stays visible during the brief wait to avoid a loading flash.
  void _reload() {
    final _FilterSnapshot snap = _currentSnapshot();
    _generation++;
    final int gen = _generation;
    _offset = 0;
    _totalCount = _pageSize + 1;

    Future.delayed(const Duration(milliseconds: 150), () async {
      if (gen != _generation) return;
      _offset = 0; // Re-assert — loadMore may have modified it during the delay
      state = const AsyncValue.loading();
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

  /// Refreshes the list while preserving all current filter settings.
  ///
  /// Unlike [ref.invalidate], this does NOT re-run [build] — filters
  /// (date range, doctor, status, type, search query) are kept intact.
  void refresh() => _reload();

  /// Appends the next page of results to the current list.
  Future<void> loadMore() async {
    if (!hasMore || _loadingMore) return;
    _setLoadingMore(true);
    final _FilterSnapshot snap = _currentSnapshot();
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

  void setDateFrom(DateTime? d) { dateFrom = d; _reload(); }
  void setDateTo(DateTime? d) { dateTo = d; _reload(); }
  void setDoctorFilter(String? id) { doctorId = id; _reload(); }
  void setClinicFilter(String? c) { clinic = c; _reload(); }
  void setStatusFilter(String? s) { status = s; _reload(); }
  void setTypeFilter(String? t) { type = t; _reload(); }
  void setSortAscending(bool asc) { _ascending = asc; _reload(); }
  bool get isAscending => _ascending;

  void setFilters({
    required DateTime? from,
    required DateTime? to,
    required String? docId,
    required String? clinicLoc,
    required String? statusFilter,
    required String? typeFilter,
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
    _reload();
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
