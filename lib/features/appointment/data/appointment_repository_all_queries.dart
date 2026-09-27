part of 'appointment_repository_impl.dart';

mixin _AllAppointmentQueries on _AppointmentRepositoryBase {
  @override
  Future<Result<List<AppointmentWithPatient>>> getAllAppointments({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? doctorId,
    String? clinic,
    String? status,
    String? type,
    String? patientQuery,
    int offset = 0,
    int limit = 30,
    bool ascending = false,
  }) {
    return _run(() async {
      final PostgrestFilterBuilder builder = _filters(
        doctorId: doctorId,
        dateFrom: dateFrom,
        dateTo: dateTo,
        status: status,
        clinic: clinic,
        type: type,
        patientQuery: patientQuery,
      );
      final List<Map<String, dynamic>> rows = await builder
          .order('scheduled_at', ascending: ascending)
          .order('created_at', ascending: ascending)
          .order('id', ascending: ascending)
          .range(offset, offset + limit - 1);
      return rows.where((row) => row['patient'] != null).map((row) {
        final names = _extractDoctorNames(row);
        return AppointmentWithPatient(
          appointment: Appointment.fromJson(row),
          patient: Patient.fromJson(row['patient'] as Map<String, dynamic>),
          doctorName: names.isEmpty ? null : names.first,
          doctorNames: names,
        );
      }).toList();
    });
  }

  @override
  Future<Result<int>> countAllAppointments({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? doctorId,
    String? clinic,
    String? status,
    String? type,
    String? patientQuery,
  }) {
    return _run(() async {
      final PostgrestFilterBuilder builder = _countFilters(
        doctorId: doctorId,
        dateFrom: dateFrom,
        dateTo: dateTo,
        status: status,
        clinic: clinic,
        type: type,
        patientQuery: patientQuery,
      );
      final response = await builder.limit(1).count(CountOption.exact);
      return response.count;
    });
  }

  PostgrestFilterBuilder _countFilters({
    required String? doctorId,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? status,
    String? clinic,
    String? type,
    String? patientQuery,
  }) {
    var builder = _service
        .from(_appointmentsTable)
        .select('id, patient:patients!inner(id)${_doctorJoin(doctorId)}');
    if (dateFrom != null) {
      builder = builder.gte('scheduled_at', dateFrom.toUtc().toIso8601String());
    }
    if (dateTo != null) {
      builder = builder.lt('scheduled_at', dateTo.toUtc().toIso8601String());
    }
    if (status != null) builder = builder.eq('status', status);
    if (clinic != null) builder = builder.eq('patient.clinic', clinic);
    if (type != null) builder = builder.eq('type', type);
    if (doctorId != null) {
      builder = builder
          .eq('doctor_filter.doctor_id', doctorId)
          .eq('doctor_filter.is_active', true);
    }
    if (patientQuery != null && patientQuery.trim().isNotEmpty) {
      for (final String token in patientQuery.trim().split(RegExp(r'\s+'))) {
        if (token.isEmpty) continue;
        final String escaped = _escapeLike(token);
        builder = builder.or(
          'full_name.ilike.%$escaped%,phone_number.ilike.%$escaped%',
          referencedTable: 'patient',
        );
      }
    }
    return builder;
  }

  PostgrestFilterBuilder _filters({
    required String? doctorId,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? status,
    String? clinic,
    String? type,
    String? patientQuery,
  }) {
    var builder = _service
        .from(_appointmentsTable)
        .select(
          '*, patient:patients!inner(*), appointment_doctors(is_active, staff:staff!doctor_id(full_name))${_doctorJoin(doctorId)}',
        );
    if (dateFrom != null) {
      builder = builder.gte('scheduled_at', dateFrom.toUtc().toIso8601String());
    }
    if (dateTo != null) {
      builder = builder.lt('scheduled_at', dateTo.toUtc().toIso8601String());
    }
    if (status != null) builder = builder.eq('status', status);
    if (clinic != null) builder = builder.eq('patient.clinic', clinic);
    if (type != null) builder = builder.eq('type', type);
    if (doctorId != null) {
      builder = builder
          .eq('doctor_filter.doctor_id', doctorId)
          .eq('doctor_filter.is_active', true);
    }
    if (patientQuery != null && patientQuery.trim().isNotEmpty) {
      for (final String token in patientQuery.trim().split(RegExp(r'\s+'))) {
        if (token.isEmpty) continue;
        final String escaped = _escapeLike(token);
        builder = builder.or(
          'full_name.ilike.%$escaped%,phone_number.ilike.%$escaped%',
          referencedTable: 'patient',
        );
      }
    }
    return builder;
  }

  String _escapeLike(String value) {
    return value
        .replaceAll('\\', '\\\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
  }
}
