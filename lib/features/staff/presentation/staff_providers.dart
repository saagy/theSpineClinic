/// Riverpod providers for the staff controllers.
///
/// Exposes:
/// - [staffRepositoryProvider] — singleton repository access.
/// - [activeDoctorsProvider] — active doctor accounts.
/// - [MyPatientsController] — patients assigned to the current doctor.
///
/// Rule 3 — all state via Riverpod.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/staff/data/staff_repository.dart';

import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_account_status.dart';

part 'staff_providers.g.dart';

/// Provides a singleton [StaffRepository] instance.
@Riverpod(keepAlive: true)
StaffRepository staffRepository(Ref ref) {
  return StaffRepositoryImpl(supabaseService: SupabaseService.instance);
}

/// Fetches all active/approved staff members with the doctor role.
@riverpod
Future<List<Staff>> activeDoctors(Ref ref) async {
  final StaffRepository repo = ref.read(staffRepositoryProvider);
  final Result<List<Staff>> result = await repo.getActiveDoctors();
  return result.when(
    success: (List<Staff> data) => data,
    failure: (AppException exception) => throw exception,
  );
}

/// Fetches all approved doctors (both active and deactivated, excluding pending applications).
///
/// Used by filter/search dropdowns (PatientListFilters, UnifiedFilterSheet)
/// where users need to filter by historical records tied to deactivated staff.
/// Deactivated doctors are visually distinguished with a "(Deactivated)" badge
/// in the UI. Operational dropdowns (creating/editing) continue to use
/// [activeDoctorsProvider] which strictly excludes inactive staff.
@riverpod
Future<List<Staff>> allDoctorsForFilter(Ref ref) async {
  final StaffRepository repo = ref.read(staffRepositoryProvider);
  final Result<List<Staff>> result = await repo.getAllStaff();
  return result.when(
    success: (List<Staff> data) => data
        .where((s) => s.role == UserRole.doctor && !s.isPendingApplication)
        .toList(),
    failure: (AppException exception) => throw exception,
  );
}

/// Controller managing the roster of patients assigned to the logged-in doctor with pagination.
@riverpod
class MyPatientsController extends _$MyPatientsController {
  String _currentQuery = '';
  ClinicLocation? _clinicFilter;
  int _offset = 0;
  String _orderBy = 'full_name';
  bool _ascending = true;
  int _totalCount = 0;
  bool _isLoadingMore = false;
  int _requestId = 0;
  static const int _pageSize = 30;

  /// Whether more pages are available to load.
  bool get hasMore => (state.value?.length ?? 0) < _totalCount;

  /// Total count of assigned patients matching filters.
  int get totalCount => _totalCount;

  /// Active clinic/branch filter.
  ClinicLocation? get currentClinicFilter => _clinicFilter;

  /// Active text query.
  String get currentQuery => _currentQuery;

  /// Current order by column.
  String get orderBy => _orderBy;

  /// Whether current sort is ascending.
  bool get isAscending => _ascending;

  @override
  Future<List<Patient>> build() async {
    final Staff? user = ref.watch(currentUserProvider).value;
    if (user == null) return const [];
    return _fetch(user.id);
  }

  Future<List<Patient>> _fetch(String doctorId) async {
    final StaffRepository repo = ref.read(staffRepositoryProvider);
    final Result<List<Patient>> result = await repo.getAssignedPatients(
      doctorId: doctorId,
      query: _currentQuery.isEmpty ? null : _currentQuery,
      clinic: _clinicFilter,
      offset: _offset,
      limit: _pageSize,
      orderBy: _orderBy,
      ascending: _ascending,
    );

    if (_offset == 0) {
      final Result<int> countResult = await repo.countAssignedPatients(
        doctorId: doctorId,
        query: _currentQuery.isEmpty ? null : _currentQuery,
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
    final Staff? user = ref.read(currentUserProvider).value;
    if (user == null) return;
    _offset = 0;
    _totalCount = 0;
    final int reqId = ++_requestId;
    state = const AsyncValue.loading();
    _fetch(user.id).then(
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

  /// Searches assigned patients by name or phone number.
  void searchNow(String query) {
    if (_currentQuery == query) return;
    _currentQuery = query;
    _applyFilter();
  }

  /// Filters assigned patients by clinic location.
  void setClinicFilter(ClinicLocation? clinic) {
    if (_clinicFilter == clinic) return;
    _clinicFilter = clinic;
    _applyFilter();
  }

  /// Sets server-side sorting.
  void setSort(String orderBy, bool ascending) {
    if (_orderBy == orderBy && _ascending == ascending) return;
    _orderBy = orderBy;
    _ascending = ascending;
    _applyFilter();
  }

  /// Loads the next page of results.
  Future<void> loadMore() async {
    if (!hasMore || _isLoadingMore || state.isLoading) return;
    final Staff? user = ref.read(currentUserProvider).value;
    if (user == null) return;
    final List<Patient> currentData = List<Patient>.from(state.value ?? []);
    _isLoadingMore = true;
    _offset += _pageSize;
    final int reqId = _requestId;
    try {
      final newPatients = await _fetch(user.id);
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

  /// Refreshes the assigned patients list.
  Future<void> refresh() async {
    final Staff? user = ref.read(currentUserProvider).value;
    if (user == null) return;
    _offset = 0;
    _totalCount = 0;
    final int reqId = ++_requestId;
    state = const AsyncValue.loading();
    try {
      final data = await _fetch(user.id);
      if (!ref.mounted || reqId != _requestId) return;
      state = AsyncValue.data(data);
    } catch (err, stack) {
      if (!ref.mounted || reqId != _requestId) return;
      state = AsyncValue.error(err, stack);
    }
  }
}
