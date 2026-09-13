part of 'all_appointments_providers.dart';

const int _pageSize = 30;

/// Query state shared by pagination, filters, and in-place status updates.
abstract class AllAppointmentsData extends AsyncNotifier<List<AppointmentWithPatient>> {
  void _reload({bool silent = false});

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

  /// The total count of appointments matching the current filters.
  int get totalCount => _totalCount;

  /// Fixed page size (30 items).
  int get pageSize => _pageSize;

  /// Current 1-based page number.
  int get currentPage => (_offset / _pageSize).floor() + 1;

  /// Total number of pages based on [_totalCount] and [_pageSize].
  int get totalPages => _totalCount <= 0 ? 1 : (_totalCount / _pageSize).ceil().clamp(1, 999999);

  /// Whether a previous page is available to navigate to.
  bool get hasPreviousPage => currentPage > 1;

  /// Whether a next page is available to navigate to.
  bool get hasNextPage => _totalCount <= 0 ? false : _offset + _pageSize < _totalCount;

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
    final String? queryParam = snap.patientQuery.isEmpty ? null : snap.patientQuery;
    final Result<List<AppointmentWithPatient>> result = await repo.getAllAppointments(
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
}
