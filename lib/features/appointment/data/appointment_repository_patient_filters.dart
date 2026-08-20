part of 'appointment_repository_impl.dart';

mixin _PatientAppointmentFilters on _AppointmentRepositoryBase {
  @override
  Future<Result<List<AppointmentWithPatient>>> getAppointmentsForPatientPaginated({
    required String patientId,
    int offset = 0,
    int limit = 30,
    Set<AppointmentStatus>? statusFilter,
    Set<AppointmentType>? typeFilter,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? doctorId,
    bool? usePackageFilter,
    bool ascending = false,
  }) {
    return _run(() async {
      final List<String>? doctorIds = await _resolveDoctorIds(
        doctorId,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
      if (doctorIds != null && doctorIds.isEmpty) {
        return <AppointmentWithPatient>[];
      }
      final PostgrestFilterBuilder builder = _patientFilters(
        patientId: patientId,
        doctorIds: doctorIds,
        statusFilter: statusFilter,
        typeFilter: typeFilter,
        dateFrom: dateFrom,
        dateTo: dateTo,
        usePackageFilter: usePackageFilter,
      );
      final List<Map<String, dynamic>> rows = await builder
          .order('scheduled_at', ascending: ascending)
          .range(offset, offset + limit - 1);
      return rows
          .where((row) => row['patient'] != null)
          .map(
            (row) => AppointmentWithPatient(
              appointment: Appointment.fromJson(row),
              patient: Patient.fromJson(row['patient'] as Map<String, dynamic>),
              doctorName: _extractDoctorName(row),
            ),
          )
          .toList();
    });
  }

  @override
  Future<Result<int>> countAppointmentsForPatient({
    required String patientId,
    Set<AppointmentStatus>? statusFilter,
    Set<AppointmentType>? typeFilter,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? doctorId,
    bool? usePackageFilter,
  }) {
    return _run(() async {
      final List<String>? doctorIds = await _resolveDoctorIds(
        doctorId,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
      if (doctorIds != null && doctorIds.isEmpty) return 0;
      final List<Map<String, dynamic>> rows = await _patientFilters(
        patientId: patientId,
        doctorIds: doctorIds,
        statusFilter: statusFilter,
        typeFilter: typeFilter,
        dateFrom: dateFrom,
        dateTo: dateTo,
        usePackageFilter: usePackageFilter,
        isCountOnly: true,
      );
      return rows.length;
    });
  }

  PostgrestFilterBuilder _patientFilters({
    required String patientId,
    required List<String>? doctorIds,
    Set<AppointmentStatus>? statusFilter,
    Set<AppointmentType>? typeFilter,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool? usePackageFilter,
    bool isCountOnly = false,
  }) {
    var builder = _service
        .from(_appointmentsTable)
        .select(
          isCountOnly
              ? 'id'
              : '*, patient:patients!inner(*), appointment_doctors(is_active, staff:staff!doctor_id(full_name))',
        )
        .eq('patient_id', patientId);
    if (dateFrom != null) {
      builder = builder.gte('scheduled_at', dateFrom.toUtc().toIso8601String());
    }
    if (dateTo != null) {
      builder = builder.lt('scheduled_at', dateTo.toUtc().toIso8601String());
    }
    if (statusFilter != null && statusFilter.isNotEmpty) {
      builder = builder.inFilter(
        'status',
        statusFilter.map((status) => status.dbValue).toList(),
      );
    }
    if (typeFilter != null && typeFilter.isNotEmpty) {
      builder = builder.inFilter(
        'type',
        typeFilter.map((type) => type.dbValue).toList(),
      );
    }
    if (usePackageFilter != null) {
      builder = builder.eq('use_package', usePackageFilter);
    }
    if (doctorIds != null) builder = builder.inFilter('id', doctorIds);
    return builder;
  }
}
