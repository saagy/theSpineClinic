part of 'appointment_repository_impl.dart';

mixin _PatientAppointmentQueries on _AppointmentRepositoryBase {
  @override
  Future<Result<List<AppointmentDoctor>>> getAppointmentDoctors(
    String appointmentId,
  ) {
    return _run(() async {
      final List<Map<String, dynamic>> rows = await _service
          .from(_appointmentDoctorsTable)
          .select()
          .eq('appointment_id', appointmentId)
          .eq('is_active', true);
      return rows.map(AppointmentDoctor.fromJson).toList();
    });
  }

  @override
  Future<Result<List<Staff>>> getAssignedDoctors(String patientId) {
    return _run(() async {
      final List<Map<String, dynamic>> rows = await _service
          .from('patient_doctors')
          .select('staff:staff!doctor_id (*)')
          .eq('patient_id', patientId);
      return rows
          .map((row) {
            final Map<String, dynamic>? staff =
                row['staff'] as Map<String, dynamic>?;
            return staff == null ? null : Staff.fromJson(staff);
          })
          .whereType<Staff>()
          .toList();
    });
  }

  @override
  Future<Result<List<Appointment>>> getAppointmentsForPatient(
    String patientId,
  ) {
    return _run(() async {
      final List<Map<String, dynamic>> rows = await _service
          .from(_appointmentsTable)
          .select()
          .eq('patient_id', patientId)
          .order('scheduled_at');
      return rows.map(Appointment.fromJson).toList();
    });
  }

  @override
  Future<Result<int>> getFutureScheduledAppointmentsCount(String patientId) {
    return _futureScheduledCount(patientId: patientId);
  }

  @override
  Future<Result<int>> getFutureScheduledAppointmentsCountForType({
    required String patientId,
    required AppointmentType type,
  }) {
    if (!type.affectsPackageBalance) {
      return Future.value(const Result.success(0));
    }
    return _futureScheduledCount(patientId: patientId, type: type);
  }

  Future<Result<int>> _futureScheduledCount({
    required String patientId,
    AppointmentType? type,
  }) {
    return _run(() async {
      var query = _service
          .from(_appointmentsTable)
          .select('id')
          .eq('patient_id', patientId)
          .eq('status', 'scheduled')
          .eq('use_package', true)
          .gte('scheduled_at', DateTime.now().toUtc().toIso8601String());
      if (type != null) query = query.eq('type', type.dbValue);
      final List<Map<String, dynamic>> rows = await query;
      return rows.length;
    });
  }
}
