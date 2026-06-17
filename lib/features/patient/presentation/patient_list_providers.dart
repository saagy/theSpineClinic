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
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/admin/presentation/branch_providers.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';

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

  /// The currently active clinic/branch filter, or null for all branches.
  ClinicLocation? get currentClinicFilter => _clinicFilter;

  /// The current search query.
  String get currentQuery => _currentQuery;

  /// The currently active doctor filter, or null for all doctors.
  String? get currentDoctorFilter => _doctorId;

  /// The current sort column (e.g. `full_name`, `last_appointment_date`, `created_at`).
  String get orderBy => _orderBy;

  /// Whether the current sort is ascending.
  bool get isAscending => _ascending;

  static const int _pageSize = 30;

  bool get hasMore => (state.value?.length ?? 0) < _totalCount;
  int _totalCount = 0;

  /// The total count of patients matching the current query/filters.
  int get totalCount => _totalCount;

  @override
  Future<List<Patient>> build() async {
    ref.listen(activeBranchProvider, (previous, next) {
      if (next != previous) {
        setClinicFilter(next);
      }
    });

    if (!_hasInitializedClinic) {
      final user = ref.read(currentUserProvider).value;
      if (user != null && user.role == UserRole.receptionist) {
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
    // last_appointment_date is not a real DB column — it's computed
    // client-side from embedded appointments. Map to a valid column
    // for the SQL ORDER BY so the query doesn't error.
    final String sqlOrderBy =
        _orderBy == 'last_appointment_date' ? 'full_name' : _orderBy;
    final Result<List<Patient>> result = await repo.getAllPatients(
      query: _currentQuery.isEmpty ? null : _currentQuery,
      doctorId: _doctorId,
      clinic: _clinicFilter,
      offset: _offset,
      limit: _pageSize,
      orderBy: sqlOrderBy,
      ascending: _ascending,
    );

    // Also get total count on first page load
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

  /// Immediately searches with the given query (debounce handled upstream).
  void searchNow(String query) {
    _currentQuery = query;
    _offset = 0;
    _totalCount = 0;
    state = const AsyncValue.loading();
    _fetch().then(
      (data) {
        if (!ref.mounted) return;
        state = AsyncValue.data(data);
      },
      onError: (err, stack) {
        if (!ref.mounted) return;
        state = AsyncValue.error(err, stack);
      },
    );
  }

  /// Applies doctor filter.
  void setDoctorFilter(String? doctorId) {
    _doctorId = doctorId;
    _offset = 0;
    _totalCount = 0;
    state = const AsyncValue.loading();
    _fetch().then(
      (data) {
        if (!ref.mounted) return;
        state = AsyncValue.data(data);
      },
      onError: (err, stack) {
        if (!ref.mounted) return;
        state = AsyncValue.error(err, stack);
      },
    );
  }

  /// Applies clinic filter.
  void setClinicFilter(ClinicLocation? clinic) {
    _clinicFilter = clinic;
    _offset = 0;
    _totalCount = 0;
    state = const AsyncValue.loading();
    _fetch().then(
      (data) {
        if (!ref.mounted) return;
        state = AsyncValue.data(data);
      },
      onError: (err, stack) {
        if (!ref.mounted) return;
        state = AsyncValue.error(err, stack);
      },
    );
  }

  /// Applies server-side sort by the given column and direction.
  void setSort(String orderBy, bool ascending) {
    _orderBy = orderBy;
    _ascending = ascending;
    _offset = 0;
    _totalCount = 0;
    state = const AsyncValue.loading();
    _fetch().then(
      (data) {
        if (!ref.mounted) return;
        state = AsyncValue.data(data);
      },
      onError: (err, stack) {
        if (!ref.mounted) return;
        state = AsyncValue.error(err, stack);
      },
    );
  }

  /// Loads the next page of results.
  Future<void> loadMore() async {
    if (!hasMore) return;
    final List<Patient> currentData = List<Patient>.from(state.value ?? []);
    _offset += _pageSize;
    try {
      final newPatients = await _fetch();
      if (!ref.mounted) return;
      state = AsyncValue.data([...currentData, ...newPatients]);
    } catch (err, stack) {
      if (!ref.mounted) return;
      _offset -= _pageSize;
      state = AsyncValue.error(err, stack);
    }
  }

  /// Force-refreshes from scratch.
  Future<void> refresh() async {
    _offset = 0;
    _totalCount = 0;
    state = const AsyncValue.loading();
    try {
      final data = await _fetch();
      if (!ref.mounted) return;
      state = AsyncValue.data(data);
    } catch (err, stack) {
      if (!ref.mounted) return;
      state = AsyncValue.error(err, stack);
    }
  }
}
