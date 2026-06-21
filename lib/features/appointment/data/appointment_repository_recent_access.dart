/// Free-function helper that backends
/// `AppointmentRepository.hasDoctorRecentAppointmentWithPatient`.
///
/// Lives in its own file to honour Rule 1 (≤ 200 lines per file) on the
/// already-over-budget appointment_repository_impl.dart.
///
/// The SQL mirrors the Supabase-side rule that a doctor retains tap access
/// to a patient's detail screen if ANY active `appointment_doctors` row links
/// them to ANY appointment for that patient whose `scheduled_at` falls inside
/// the access window of `[scheduled_at - 7d, scheduled_at + 1d]`.
///
/// Computed as `scheduled_at BETWEEN NOW() - INTERVAL '1 day'
///                                       AND NOW() + INTERVAL '7 days'`.
library;

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';

/// Returns true when at least one active appointment links [doctorId] to
/// [patientId] with `scheduled_at` inside the patient-access window.
///
/// Examines all appointments between the doctor and the patient, not a
/// specific appointment id — required so a doctor opening appointment X
/// detail still has tap-through when their NEXT appointment Y with the
/// same patient falls inside the window.
Future<Result<bool>> checkRecentDoctorPatientAppointment({
  required SupabaseService service,
  required String patientId,
  required String doctorId,
}) async {
  try {
    final DateTime nowUtc = DateTime.now().toUtc();
    final String lowerBound =
        nowUtc.subtract(const Duration(days: 1)).toIso8601String();
    final String upperBound =
        nowUtc.add(const Duration(days: 7)).toIso8601String();
    final List<Map<String, dynamic>> rows = await service.guardQuery(() => service
        .from('appointment_doctors')
        .select('id, appointments!inner(patient_id, scheduled_at, status)')
        .eq('doctor_id', doctorId)
        .eq('is_active', true)
        .eq('appointments.patient_id', patientId)
        .gte('appointments.scheduled_at', lowerBound)
        .lte('appointments.scheduled_at', upperBound)
        .limit(1));
    return Result.success(rows.isNotEmpty);
  } on AppException catch (e) {
    return Result.failure(e);
  } catch (e) {
    return Result.failure(AppException.fromSupabaseException(e));
  }
}
