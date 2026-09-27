import 'package:spine_clinic_app/core/errors/result.dart';
import 'appointment_repository.dart';

/// Loads a complete, bounded date interval without relying on the API row cap.
extension ScheduleLoader on AppointmentRepository {
  Future<Result<List<AppointmentWithPatient>>> getScheduleAppointments({
    required DateTime dateFrom,
    required DateTime dateTo,
    String? doctorId,
    String? clinic,
  }) async {
    final Map<String, AppointmentWithPatient> items = {};
    int offset = 0;
    while (true) {
      final result = await getAllAppointments(
        dateFrom: dateFrom,
        dateTo: dateTo,
        doctorId: doctorId,
        clinic: clinic,
        offset: offset,
        limit: 500,
        ascending: true,
      );
      if (result case Failure(:final exception)) {
        return Result.failure(exception);
      }
      final List<AppointmentWithPatient> page = result.dataOrNull!;
      if (page.isEmpty) return Result.success(items.values.toList());
      for (final item in page) {
        items[item.appointment.id] = item;
      }
      // Continue to an empty page even if a project's row cap is below 500.
      offset += page.length;
    }
  }
}
