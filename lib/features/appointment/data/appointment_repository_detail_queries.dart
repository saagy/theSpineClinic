part of 'appointment_repository_impl.dart';

mixin _AppointmentDetailQueries on _AppointmentRepositoryBase {
  @override
  Future<Result<Appointment>> getAppointmentById(String appointmentId) {
    return _run(() async {
      final Map<String, dynamic> row = await _service
          .from(_appointmentsTable)
          .select()
          .eq('id', appointmentId)
          .single();
      return Appointment.fromJson(row);
    });
  }

  @override
  Future<Result<List<AppointmentDoctor>>> getAllAppointmentDoctors(
    String appointmentId,
  ) {
    return _run(() async {
      final List<Map<String, dynamic>> rows = await _service
          .from(_appointmentDoctorsTable)
          .select()
          .eq('appointment_id', appointmentId);
      return rows.map(AppointmentDoctor.fromJson).toList();
    });
  }

  @override
  Future<Result<List<DoctorScheduleItem>>> getDoctorSchedule(String doctorId) {
    return _run(() async {
      final List<Map<String, dynamic>> rows = await _service
          .from(_appointmentDoctorsTable)
          .select('''
            *,
            appointment:appointments!appointment_id(
              *,
              patient:patients!patient_id(*)
            )
          ''')
          .eq('doctor_id', doctorId)
          .eq('is_active', true);
      final List<DoctorScheduleItem> items = <DoctorScheduleItem>[];
      for (final Map<String, dynamic> row in rows) {
        final Map<String, dynamic>? appointment =
            row['appointment'] as Map<String, dynamic>?;
        final Map<String, dynamic>? patient =
            appointment?['patient'] as Map<String, dynamic>?;
        if (appointment == null || patient == null) continue;
        items.add(
          DoctorScheduleItem(
            appointment: Appointment.fromJson(appointment),
            appointmentDoctor: AppointmentDoctor.fromJson(row),
            patient: Patient.fromJson(patient),
          ),
        );
      }
      items.sort(
        (a, b) =>
            a.appointment.scheduledAt.compareTo(b.appointment.scheduledAt),
      );
      return items;
    });
  }
}
