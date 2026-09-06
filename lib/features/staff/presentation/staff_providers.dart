/// Riverpod providers for staff controllers and doctor rosters.
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
StaffRepository staffRepository(Ref ref) =>
    StaffRepositoryImpl(supabaseService: SupabaseService.instance);

/// Fetches all active/approved staff members with the doctor role.
@riverpod
Future<List<Staff>> activeDoctors(Ref ref) async {
  final Result<List<Staff>> result =
      await ref.read(staffRepositoryProvider).getActiveDoctors();
  return result.when(
    success: (data) => data,
    failure: (exception) => throw exception,
  );
}

/// Fetches approved doctors (active and deactivated) for filter dropdowns.
@riverpod
Future<List<Staff>> allDoctorsForFilter(Ref ref) async {
  final Result<List<Staff>> result =
      await ref.read(staffRepositoryProvider).getAllStaff();
  return result.when(
    success: (data) => data
        .where((s) => s.role == UserRole.doctor && !s.isPendingApplication)
        .toList(),
    failure: (exception) => throw exception,
  );
}

/// Controller managing the roster of patients assigned to the doctor.
@Riverpod(keepAlive: true)
class MyPatientsController extends _$MyPatientsController {
  String _currentQuery = '';
  ClinicLocation? _clinicFilter;
  int _offset = 0;
  String _orderBy = 'full_name';
  bool _ascending = true;
  int? _totalCount;
  bool _isLoadingMore = false;
  int _requestId = 0;
  static const int _pageSize = 30;

  bool get hasMore => _totalCount == null ? (state.value?.length ?? 0) >= _pageSize : (state.value?.length ?? 0) < _totalCount!;
  int? get totalCount => _totalCount;
  ClinicLocation? get currentClinicFilter => _clinicFilter;
  String get currentQuery => _currentQuery;
  String get orderBy => _orderBy;
  bool get isAscending => _ascending;

  @override
  Future<List<Patient>> build() async {
    final Staff? user = ref.watch(currentUserProvider).value;
    if (user == null) return const [];
    final int reqId = ++_requestId;
    final res = await _fetch(user.id);
    if (reqId == _requestId) {
      _totalCount = res.totalCount;
    }
    return res.patients;
  }

  Future<({List<Patient> patients, int? totalCount})> _fetch(String doctorId) async {
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

    int? resolvedCount;
    if (_offset == 0) {
      final Result<int> countResult = await repo.countAssignedPatients(
        doctorId: doctorId,
        query: _currentQuery.isEmpty ? null : _currentQuery,
        clinic: _clinicFilter,
      );
      countResult.when(
        success: (int count) => resolvedCount = count,
        failure: (_) => resolvedCount = null,
      );
    }

    return result.when(
      success: (List<Patient> data) => (patients: data, totalCount: resolvedCount),
      failure: (AppException exception) => throw exception,
    );
  }

  void _applyFilter() {
    _offset = 0;
    _totalCount = null;
    _loadPage();
  }

  Future<void> _loadPage() async {
    final Staff? user = ref.read(currentUserProvider).value;
    if (user == null) return;
    final int reqId = ++_requestId;
    state = const AsyncValue.loading();
    try {
      final res = await _fetch(user.id);
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

  int get currentPage => (_offset / _pageSize).floor() + 1;
  int get totalPages => _totalCount == null ? (hasPreviousPage || hasNextPage ? currentPage + 1 : currentPage) : (_totalCount! / _pageSize).ceil().clamp(1, 999999);
  bool get hasPreviousPage => _offset > 0;
  bool get hasNextPage => _totalCount == null ? (state.value?.length ?? 0) >= _pageSize : _offset + _pageSize < _totalCount!;
  int get pageSize => _pageSize;

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
    final Staff? user = ref.read(currentUserProvider).value;
    if (user == null) return;
    final List<Patient> currentData = List<Patient>.from(state.value ?? []);
    _isLoadingMore = true;
    _offset += _pageSize;
    final int reqId = _requestId;
    try {
      final res = await _fetch(user.id);
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

  Future<void> refresh() async {
    _offset = 0;
    _totalCount = null;
    await _loadPage();
  }
}
