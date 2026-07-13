part of 'appointment_repository_impl.dart';

mixin _PatientAppointmentFilters on _AppointmentRepositoryBase {
  @override
  Future<Result<List<Appointment>>> getAppointmentsForPatientPaginated({
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
      final List<String>? doctorIds = await _resolveDoctorIds(doctorId);
      if (doctorIds != null && doctorIds.isEmpty) return <Appointment>[];
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
      return rows.map(Appointment.fromJson).toList();
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
      final List<String>? doctorIds = await _resolveDoctorIds(doctorId);
      if (doctorIds != null && doctorIds.isEmpty) return 0;
      final List<Map<String, dynamic>> rows = await _patientFilters(
        patientId: patientId,
        doctorIds: doctorIds,
        statusFilter: statusFilter,
        typeFilter: typeFilter,
        dateFrom: dateFrom,
        dateTo: dateTo,
        usePackageFilter: usePackageFilter,
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
  }) {
    var builder = _service
        .from(_appointmentsTable)
        .select()
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
