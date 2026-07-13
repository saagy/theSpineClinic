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
    return _run(() async {
      final List<Map<String, dynamic>> rows = await _service
          .from(_appointmentDoctorsTable)
          .select()
          .eq('appointment_id', appointmentId);
      final List<String> active = rows
          .where((row) => row['is_active'] == true)
          .map((row) => row['doctor_id'] as String)
          .toList();
      final List<String> inactive = rows
          .where((row) => row['is_active'] == false)
          .map((row) => row['doctor_id'] as String)
          .toList();
      final List<String> deactivate = active
          .where((id) => !doctorIds.contains(id))
          .toList();
      final List<String> reactivate = doctorIds
          .where(inactive.contains)
          .toList();
      final List<String> insert = doctorIds
          .where((id) => !active.contains(id) && !inactive.contains(id))
          .toList();
      if (deactivate.isNotEmpty) {
        await _service
            .from(_appointmentDoctorsTable)
            .update(<String, dynamic>{'is_active': false})
            .eq('appointment_id', appointmentId)
            .inFilter('doctor_id', deactivate);
      }
      if (reactivate.isNotEmpty) {
        await _service
            .from(_appointmentDoctorsTable)
            .update(<String, dynamic>{
              'is_active': true,
              'added_by': editorId,
              'added_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('appointment_id', appointmentId)
            .inFilter('doctor_id', reactivate);
      }
      if (insert.isNotEmpty) {
        final List<Map<String, dynamic>> newRows = insert
            .map(
              (doctorId) => <String, dynamic>{
                'appointment_id': appointmentId,
                'doctor_id': doctorId,
                'is_active': true,
                'added_by': editorId,
                'added_at': DateTime.now().toUtc().toIso8601String(),
              },
            )
            .toList();
        await _service.from(_appointmentDoctorsTable).insert(newRows);
      }
    });
  }

  @override
  Future<Result<void>> createRecurringBookings({
    required String patientId,
    required AppointmentType type,
    required List<DateTime> slots,
    required bool usePackage,
    required String? creatorId,
    required List<String> doctorIds,
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
        },
      ),
    );
  }
}
