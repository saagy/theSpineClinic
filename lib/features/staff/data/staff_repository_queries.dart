import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';

Future<Result<int>> countUpcomingStaffAppointments(
  SupabaseService service,
  String staffId,
) async {
  try {
    final now = DateTime.now().toUtc().toIso8601String();
    final rows = await service.guardQuery(
      () => service
          .from('appointment_doctors')
          .select('appointment_id, appointments!inner(scheduled_at)')
          .eq('doctor_id', staffId)
          .eq('is_active', true)
          .gte('appointments.scheduled_at', now),
    );
    return Result.success(rows.length);
  } on AppException catch (e) {
    return Result.failure(e);
  } on Exception catch (e) {
    return Result.failure(AppException.fromSupabaseException(e));
  }
}
