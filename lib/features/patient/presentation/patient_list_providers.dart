/// Riverpod providers for the patient list screen with pagination.
///
/// Provides debounced search, doctor/branch filters, and
/// infinite-scroll pagination via [PatientList] notifier.
///
/// Rule 3 — all state via Riverpod.
/// Rule 12 — debounce is handled by AppSearchBar widget (300ms);
///           the notifier's [searchNow] fires immediately.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/admin/presentation/branch_providers.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';

part 'patient_list_providers.g.dart';

/// Manages the patient list with filters and pagination.
///
/// Search debounce is handled by [AppSearchBar]; call [searchNow] directly.
@riverpod
class PatientList extends _$PatientList {
  String _currentQuery = '';
  String? _doctorId;
  ClinicLocation? _clinicFilter;
  int _offset = 0;
  String _orderBy = 'full_name';
  bool _ascending = true;
  bool _hasInitializedClinic = false;
  bool _isLoadingMore = false;
  int _requestId = 0;
  int _totalCount = 0;
  static const int _pageSize = 30;

  /// The currently active clinic/branch filter, or null for all branches.
  ClinicLocation? get currentClinicFilter => _clinicFilter;

  /// The current search query.
  String get currentQuery => _currentQuery;

  /// The currently active doctor filter, or null for all doctors.
  String? get currentDoctorFilter => _doctorId;

  /// The current sort column.
  String get orderBy => _orderBy;

  /// Whether the current sort is ascending.
  bool get isAscending => _ascending;

  /// Whether more records exist beyond current loaded count.
  bool get hasMore => (state.value?.length ?? 0) < _totalCount;

  /// Total count of patients matching current query/filters.
  int get totalCount => _totalCount;

  @override
  Future<List<Patient>> build() async {
    ref.listen(activeBranchProvider, (previous, next) {
      if (next != previous) {
        setClinicFilter(next);
      }
    });

    final user = ref.watch(currentUserProvider).value;
    if (!_hasInitializedClinic && user != null) {
      if (user.role == UserRole.receptionist) {
        _clinicFilter = ref.read(activeBranchProvider);
      } else {
        _clinicFilter = null;
      }
      _hasInitializedClinic = true;
    }

    return _fetch();
  }

  Future<List<Patient>> _fetch() async {
    final repo = ref.read(patientRepositoryProvider);
    final Result<List<Patient>> result = await repo.getAllPatients(
      query: _currentQuery.isEmpty ? null : _currentQuery,
      doctorId: _doctorId,
      clinic: _clinicFilter,
      offset: _offset,
      limit: _pageSize,
      orderBy: _orderBy,
      ascending: _ascending,
    );

    if (_offset == 0) {
      final Result<int> countResult = await repo.countAllPatients(
        query: _currentQuery.isEmpty ? null : _currentQuery,
        doctorId: _doctorId,
        clinic: _clinicFilter,
      );
      countResult.when(
        success: (int count) => _totalCount = count,
        failure: (_) => _totalCount = 0,
      );
    }

    return result.when(
      success: (List<Patient> data) => data,
      failure: (AppException exception) => throw exception,
    );
  }

  void _applyFilter() {
    _offset = 0;
    _totalCount = 0;
    final int reqId = ++_requestId;
    state = const AsyncValue.loading();
    _fetch().then(
      (data) {
        if (!ref.mounted || reqId != _requestId) return;
        state = AsyncValue.data(data);
      },
      onError: (err, stack) {
        if (!ref.mounted || reqId != _requestId) return;
        state = AsyncValue.error(err, stack);
      },
    );
  }

  /// Immediately searches with the given query.
  void searchNow(String query) {
    if (_currentQuery == query) return;
    _currentQuery = query;
    _applyFilter();
  }

  /// Applies doctor filter.
  void setDoctorFilter(String? doctorId) {
    if (_doctorId == doctorId) return;
    _doctorId = doctorId;
    _applyFilter();
  }

  /// Applies clinic filter.
  void setClinicFilter(ClinicLocation? clinic) {
    if (_clinicFilter == clinic) return;
    _clinicFilter = clinic;
    _applyFilter();
  }

  /// Applies server-side sort by column and direction.
  void setSort(String orderBy, bool ascending) {
    if (_orderBy == orderBy && _ascending == ascending) return;
    _orderBy = orderBy;
    _ascending = ascending;
    _applyFilter();
  }

  /// Loads next page of results with mutex locking.
  Future<void> loadMore() async {
    if (!hasMore || _isLoadingMore || state.isLoading) return;
    final List<Patient> currentData = List<Patient>.from(state.value ?? []);
    _isLoadingMore = true;
    _offset += _pageSize;
    final int reqId = _requestId;
    try {
      final newPatients = await _fetch();
      if (!ref.mounted || reqId != _requestId) return;
      state = AsyncValue.data([...currentData, ...newPatients]);
    } catch (err, stack) {
      if (!ref.mounted || reqId != _requestId) return;
      _offset -= _pageSize;
      state = AsyncValue.error(err, stack);
    } finally {
      _isLoadingMore = false;
    }
  }

  /// Force-refreshes from scratch.
  Future<void> refresh() async {
    _offset = 0;
    _totalCount = 0;
    final int reqId = ++_requestId;
    state = const AsyncValue.loading();
    try {
      final data = await _fetch();
      if (!ref.mounted || reqId != _requestId) return;
      state = AsyncValue.data(data);
    } catch (err, stack) {
      if (!ref.mounted || reqId != _requestId) return;
      state = AsyncValue.error(err, stack);
    }
  }
}
