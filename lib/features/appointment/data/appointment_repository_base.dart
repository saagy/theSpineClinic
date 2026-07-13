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

  Future<List<String>?> _resolveDoctorIds(String? doctorId) async {
    if (doctorId == null) return null;
    final List<Map<String, dynamic>> rows = await _service
        .from(_appointmentDoctorsTable)
        .select('appointment_id')
        .eq('doctor_id', doctorId)
        .eq('is_active', true);
    return rows.map((row) => row['appointment_id'] as String).toList();
  }
}
