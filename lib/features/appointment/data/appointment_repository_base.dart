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

  String _doctorJoin(String? doctorId) =>
      doctorId == null ? '' : ', doctor_filter:appointment_doctors!inner()';

  List<String> _extractDoctorNames(Map<String, dynamic> row) {
    final doctors = row['appointment_doctors'] as List<dynamic>?;
    if (doctors == null || doctors.isEmpty) return const <String>[];
    final names = <String>[];
    for (final d in doctors) {
      if (d is Map<String, dynamic> && d['is_active'] == true) {
        final staff = d['staff'] as Map<String, dynamic>?;
        final name = staff?['full_name'] as String?;
        if (name != null && name.trim().isNotEmpty) {
          names.add(name.trim());
        }
      }
    }
    return names;
  }
}
