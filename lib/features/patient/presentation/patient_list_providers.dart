/// Riverpod providers for the patient list screen with pagination and search.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/admin/presentation/branch_providers.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_filters.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';

part 'patient_list_providers.g.dart';

/// Manages the patient list with filters and pagination.
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
  int? _totalCount;
  static const int _pageSize = 30;

  PatientFilters get currentFilters => PatientFilters(
      clinic: _clinicFilter, doctorId: _doctorId, search: _currentQuery.isEmpty ? null : _currentQuery);

  ClinicLocation? get currentClinicFilter => _clinicFilter;
  String get currentQuery => _currentQuery;
  String? get currentDoctorFilter => _doctorId;
  String get orderBy => _orderBy;
  bool get isAscending => _ascending;
  bool get hasMore => _totalCount == null
      ? (state.value?.length ?? 0) >= _pageSize
      : (state.value?.length ?? 0) < _totalCount!;
  int? get totalCount => _totalCount;

  @override
  Future<List<Patient>> build() async {
    ref.listen(activeBranchProvider, (previous, next) {
      if (next != previous) {
        setClinicFilter(next);
      }
    });

    final user = ref.watch(currentUserProvider).value;
    if (!_hasInitializedClinic && user != null) {
      _clinicFilter = user.role == UserRole.receptionist
          ? ref.read(activeBranchProvider)
          : null;
      _hasInitializedClinic = true;
    }

    final int reqId = ++_requestId;
    final res = await _fetch(currentFilters);
    if (reqId == _requestId) {
      _totalCount = res.totalCount;
    }
    return res.patients;
  }

  Future<({List<Patient> patients, int? totalCount})> _fetch(
    PatientFilters filters,
  ) async {
    final repo = ref.read(patientRepositoryProvider);
    final Result<List<Patient>> result = await repo.getAllPatients(
      filters: filters,
      offset: _offset,
      limit: _pageSize,
      orderBy: _orderBy,
      ascending: _ascending,
    );

    int? resolvedCount;
    if (_offset == 0) {
      final Result<int> countResult =
          await repo.countAllPatients(filters: filters);
      countResult.when(
        success: (int count) => resolvedCount = count,
        failure: (_) => resolvedCount = null,
      );
    }

    return result.when(
      success: (List<Patient> data) =>
          (patients: data, totalCount: resolvedCount),
      failure: (AppException exception) => throw exception,
    );
  }

  void _applyFilter() {
    _offset = 0;
    _totalCount = null;
    _loadPage();
  }

  Future<void> _loadPage() async {
    final int reqId = ++_requestId;
    state = const AsyncValue.loading();
    final filters = currentFilters;
    try {
      final res = await _fetch(filters);
      if (!ref.mounted || reqId != _requestId) return;
      if (_offset == 0) {
        _totalCount = res.totalCount;
      }
      state = AsyncValue.data(res.patients);
    } catch (err, stack) {
      if (!ref.mounted || reqId != _requestId) return;
      state = AsyncValue.error(err, stack);
    }
  }

  /// Immediately searches with the given query.
  void searchNow(String query) {
    if (_currentQuery == query) return;
    _currentQuery = query;
    _applyFilter();
  }

  /// Applies multiple filter and sort parameters in a single atomic update.
  void applyFilters({
    ClinicLocation? clinic,
    String? doctorId,
    String? orderBy,
    bool? ascending,
  }) {
    final user = ref.read(currentUserProvider).value;
    final canDoc = user == null || user.role != UserRole.doctor || user.isSeniorDoctor;
    final targetDoc = canDoc ? doctorId : _doctorId;
    final targetOrder = orderBy ?? _orderBy;
    final targetAsc = ascending ?? _ascending;
    if (_clinicFilter == clinic && _doctorId == targetDoc && _orderBy == targetOrder && _ascending == targetAsc) {
      return;
    }
    _clinicFilter = clinic;
    _doctorId = targetDoc;
    _orderBy = targetOrder;
    _ascending = targetAsc;
    _applyFilter();
  }

  void setDoctorFilter(String? docId) => applyFilters(clinic: _clinicFilter, doctorId: docId);
  void setClinicFilter(ClinicLocation? clinic) => applyFilters(clinic: clinic, doctorId: _doctorId);
  void setSort(String order, bool asc) => applyFilters(clinic: _clinicFilter, doctorId: _doctorId, orderBy: order, ascending: asc);

  int get currentPage => (_offset / _pageSize).floor() + 1;
  int get totalPages => _totalCount == null ? (hasPreviousPage || hasNextPage ? currentPage + 1 : currentPage) : (_totalCount! / _pageSize).ceil().clamp(1, 999999);
  bool get hasPreviousPage => _offset > 0;
  bool get hasNextPage => _totalCount == null ? (state.value?.length ?? 0) >= _pageSize : _offset + _pageSize < _totalCount!;
  int get pageSize => _pageSize;
  int get offset => _offset;

  Future<void> goToPage(int page) async {
    if (page < 1 || page > totalPages) return;
    final targetOffset = (page - 1) * _pageSize;
    if (_offset == targetOffset) return;
    _offset = targetOffset;
    await _loadPage();
  }
  Future<void> nextPage() => goToPage(currentPage + 1);
  Future<void> previousPage() => goToPage(currentPage - 1);
  Future<void> loadMore() async {
    if (!hasMore || _isLoadingMore || state.isLoading) return;
    final List<Patient> currentData = List<Patient>.from(state.value ?? []);
    _isLoadingMore = true;
    _offset += _pageSize;
    final int reqId = _requestId;
    try {
      final res = await _fetch(currentFilters);
      if (!ref.mounted || reqId != _requestId) return;
      state = AsyncValue.data([...currentData, ...res.patients]);
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
    _totalCount = null;
    await _loadPage();
  }
}
