part of 'receptionist_appointments_providers.dart';

abstract class _ReceptionistScheduleBase
    extends Notifier<ReceptionistAppointmentsState> {
  _ReceptionistScheduleBase({DateTime Function()? now})
    : _freshness = ScheduleFreshness(now: now);

  final ScheduleFreshness _freshness;
  final Map<DateTime, List<AppointmentWithPatient>> _weekCache =
      <DateTime, List<AppointmentWithPatient>>{};
  String? _cacheScope;
  String? _lastUserId;
  int _requestId = 0;

  AppointmentRepository get _repository =>
      ref.read(appointmentRepositoryProvider);

  ClinicLocation? get _clinic {
    final Staff? user = ref.read(currentUserProvider).value;
    if (user?.role == UserRole.superAdmin) {
      final String? override = ref.read(adminBranchFilterProvider);
      if (override == 'tagamoa') return ClinicLocation.tagamoa;
      if (override == 'masr_elgedida') return ClinicLocation.masrElgedida;
      return null;
    }
    return ref.read(activeBranchProvider);
  }

  Future<void> _loadWeek(
    DateTime date, {
    required bool useCache,
    bool background = false,
  }) async {
    final Staff? user = ref.read(currentUserProvider).value;
    if (user == null) return;
    final DateTime selected = ScheduleWeek.day(date);
    final DateTime weekStart = ScheduleWeek.start(selected);
    final ClinicLocation? clinic = _clinic;
    final String scope =
        '${user.id}|${state.filterDoctorId}|${clinic?.dbValue ?? 'all'}';
    if (_cacheScope != scope) {
      _cacheScope = scope;
      _weekCache.clear();
      _freshness.clear();
    }

    final int requestId = ++_requestId;
    final int revision = _freshness.revision;
    final List<AppointmentWithPatient>? cached = _weekCache[weekStart];
    if (useCache && cached != null) {
      state = state.copyWith(
        allItems: cached,
        selectedDate: selected,
        loading: false,
        clearError: true,
      );
      return;
    }

    if (!background) {
      state = state.copyWith(
        allItems: const <AppointmentWithPatient>[],
        selectedDate: selected,
        loading: true,
        clearError: true,
      );
    }
    final Result<List<AppointmentWithPatient>> result = await _repository
        .getScheduleAppointments(
          dateFrom: weekStart,
          dateTo: DateTime(weekStart.year, weekStart.month, weekStart.day + 7),
          doctorId: state.filterDoctorId,
          clinic: clinic?.dbValue,
        );
    if (!ref.mounted ||
        requestId != _requestId ||
        (background && revision != _freshness.revision)) {
      return;
    }

    result.when(
      success: (List<AppointmentWithPatient> data) {
        _weekCache[weekStart] = data;
        _freshness.loaded(weekStart);
        state = state.copyWith(
          allItems: _weekCache[weekStart] ?? <AppointmentWithPatient>[],
          loading: false,
          clearError: true,
        );
      },
      failure: (AppException exception) {
        if (!background) {
          state = state.copyWith(error: exception, loading: false);
        }
      },
    );
  }

  Future<void> refreshIfStale() async {
    final DateTime selected = state.selectedDate ?? DateTime.now();
    if (state.loading ||
        !_freshness.startRefresh(ScheduleWeek.start(selected))) {
      return;
    }
    try {
      await _loadWeek(selected, useCache: false, background: true);
    } finally {
      _freshness.finishRefresh();
    }
  }
}
