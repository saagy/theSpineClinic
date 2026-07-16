part of 'appointment_repository_impl.dart';

mixin _AppointmentRepositoryBase implements AppointmentRepository {
  SupabaseService get _service;

  Future<Result<T>> _run<T>(Future<T> Function() action) async {
    try {
      final T result = await _service.guardQuery(action);
      return Result.success(result);
    } on AppException catch (error) {
      return Result.failure(error);
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }

  Future<List<String>?> _resolveDoctorIds(
    String? doctorId, {
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    if (doctorId == null) return null;
    PostgrestFilterBuilder query = _service
        .from(_appointmentDoctorsTable)
        .select('appointment_id, appointments!inner(scheduled_at)')
        .eq('doctor_id', doctorId)
        .eq('is_active', true);
    if (dateFrom != null) {
      query = query.gte(
        'appointments.scheduled_at',
        dateFrom.toUtc().toIso8601String(),
      );
    }
    if (dateTo != null) {
      query = query.lt(
        'appointments.scheduled_at',
        dateTo.toUtc().toIso8601String(),
      );
    }
    final List<Map<String, dynamic>> rows = await query;
    return rows.map((row) => row['appointment_id'] as String).toList();
  }
}
