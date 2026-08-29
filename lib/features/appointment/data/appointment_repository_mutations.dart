part of 'appointment_repository_impl.dart';

mixin _AppointmentMutations on _AppointmentRepositoryBase {
  @override
  Future<Result<void>> updateAppointmentStatus(
    String appointmentId,
    AppointmentStatus status,
  ) {
    return _run(
      () => _service
          .from(_appointmentsTable)
          .update(<String, dynamic>{'status': status.dbValue})
          .eq('id', appointmentId),
    );
  }

  @override
  Future<Result<String>> createAppointment(Appointment appointment) {
    return _run(() async {
      final Map<String, dynamic> json = appointment.toJson();
      if (appointment.id.isEmpty) json.remove('id');
      final Map<String, dynamic> row = await _service
          .from(_appointmentsTable)
          .insert(json)
          .select('id')
          .single();
      return row['id'] as String;
    });
  }

  @override
  Future<Result<void>> updateAppointment(Appointment appointment) {
    return _run(
      () => _service
          .from(_appointmentsTable)
          .update(<String, dynamic>{
            'scheduled_at': appointment.scheduledAt.toIso8601String(),
            'type': appointment.type.dbValue,
            'use_package': appointment.usePackage,
          })
          .eq('id', appointment.id),
    );
  }

  @override
  Future<Result<void>> deleteAppointment(String appointmentId) {
    return _run(
      () => _service.from(_appointmentsTable).delete().eq('id', appointmentId),
    );
  }

  @override
  Future<Result<void>> updateAppointmentDoctors(
    String appointmentId,
    List<String> doctorIds,
    String? editorId,
  ) {
    return _run(
      () => _service.rpc(
        'update_appointment_doctors',
        params: <String, dynamic>{
          'p_appointment_id': appointmentId,
          'p_doctor_ids': doctorIds,
          'p_editor_id': editorId,
        },
      ),
    );
  }

  @override
  Future<Result<void>> createRecurringBookings({
    required String patientId,
    required AppointmentType type,
    required List<DateTime> slots,
    required bool usePackage,
    required String? creatorId,
    required List<String> doctorIds,
    DateTime? expectedNextVisitDate,
  }) {
    return _run(
      () => _service.rpc(
        'book_recurring_appointments',
        params: <String, dynamic>{
          'p_patient_id': patientId,
          'p_type': type.dbValue,
          'p_slots': slots
              .map((slot) => slot.toUtc().toIso8601String())
              .toList(),
          'p_use_package': type.affectsPackageBalance ? usePackage : false,
          'p_creator_id': creatorId,
          'p_doctor_ids': doctorIds,
          'p_expected_next_visit_date': expectedNextVisitDate == null
              ? null
              : _dateOnly(expectedNextVisitDate),
        },
      ),
    );
  }

  @override
  Future<Result<BulkDoctorReplacementResult>> bulkReplaceDoctor({
    required String absentDoctorId,
    required List<String> replacementDoctorIds,
    required List<String> appointmentIds,
    required DateTime day,
  }) {
    return _run(() async {
      final List<Map<String, dynamic>> rows = await _service.rpc(
        'bulk_replace_appointment_doctor',
        params: <String, dynamic>{
          'p_absent_doctor_id': absentDoctorId,
          'p_replacement_doctor_ids': replacementDoctorIds,
          'p_appointment_ids': appointmentIds,
          'p_day': _dateOnly(day),
        },
      );
      return BulkDoctorReplacementResult.fromJson(rows.single);
    });
  }

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
