part of 'appointment_repository_impl.dart';

mixin _TodayAppointmentQueries on _AppointmentRepositoryBase {
  @override
  Future<Result<List<Appointment>>> getAppointmentsForToday(
    ClinicLocation? clinic,
  ) {
    return _run(() async {
      final DateTime now = DateTime.now();
      final DateTime start = DateTime(now.year, now.month, now.day).toUtc();
      final DateTime end = start.add(const Duration(days: 1));
      var query = _service
          .from(_appointmentsTable)
          .select('*, patient:patients!inner(clinic)');
      if (clinic != null) query = query.eq('patient.clinic', clinic.dbValue);
      final List<Map<String, dynamic>> rows = await query
          .gte('scheduled_at', start.toIso8601String())
          .lt('scheduled_at', end.toIso8601String())
          .order('scheduled_at');
      return rows.map(Appointment.fromJson).toList();
    });
  }

  @override
  Future<Result<List<AppointmentWithPatient>>> getTodayAppointmentsWithPatients(
    ClinicLocation? clinic,
  ) {
    return _run(() async {
      final DateTime now = DateTime.now();
      final DateTime start = DateTime(now.year, now.month, now.day).toUtc();
      final DateTime end = start.add(const Duration(days: 1));
      var query = _service
          .from(_appointmentsTable)
          .select('*, patient:patients!inner(*)');
      if (clinic != null) query = query.eq('patient.clinic', clinic.dbValue);
      final List<Map<String, dynamic>> rows = await query
          .gte('scheduled_at', start.toIso8601String())
          .lt('scheduled_at', end.toIso8601String())
          .order('scheduled_at');
      return rows.map(_withPatient).toList();
    });
  }

  AppointmentWithPatient _withPatient(Map<String, dynamic> row) {
    return AppointmentWithPatient(
      appointment: Appointment.fromJson(row),
      patient: Patient.fromJson(row['patient'] as Map<String, dynamic>),
    );
  }
}
