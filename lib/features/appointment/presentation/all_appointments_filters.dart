part of 'all_appointments_providers.dart';

/// Filter changes explicitly reload; status patches preserve the current page.
mixin AllAppointmentsFilters on AllAppointmentsData {
  void setDateFrom(DateTime? d) {
    dateFrom = d;
    _reload(silent: false);
  }

  void setDateTo(DateTime? d) {
    dateTo = d;
    _reload(silent: false);
  }

  void setDoctorFilter(String? id) {
    doctorId = id;
    _reload(silent: false);
  }

  void setClinicFilter(String? c) {
    clinic = c;
    _reload(silent: false);
  }

  void setStatusFilter(String? s) {
    status = s;
    _reload(silent: false);
  }

  void setTypeFilter(String? t) {
    type = t;
    _reload(silent: false);
  }

  void setSortAscending(bool asc) {
    _ascending = asc;
    _reload(silent: false);
  }

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
    _reload(silent: false);
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
    _reload(silent: false);
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
    _reload(silent: false);
  }
}
