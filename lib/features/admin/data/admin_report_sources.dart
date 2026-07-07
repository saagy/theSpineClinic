import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';

Future<List<Map<String, dynamic>>> reportPatients(
  SupabaseService service,
  ClinicLocation? clinic,
) {
  return service.guardQuery(() {
    final query = service
        .from('patients')
        .select('created_at, clinic, session_balance, traction_balance');
    return clinic == null ? query : query.eq('clinic', clinic.dbValue);
  });
}

Future<List<Map<String, dynamic>>> reportPayments(
  SupabaseService service,
  ClinicLocation? clinic,
  DateTime start,
  DateTime end,
) {
  return service.guardQuery(() {
    final query = service
        .from('payment_records')
        .select('amount, recorded_at, patient:patients!inner(clinic)')
        .gte('recorded_at', start.toIso8601String())
        .lte('recorded_at', end.toIso8601String());
    return clinic == null ? query : query.eq('patient.clinic', clinic.dbValue);
  });
}

Future<List<Map<String, dynamic>>> reportAppointments(
  SupabaseService service,
  ClinicLocation? clinic,
  DateTime start,
  DateTime end,
) {
  return service.guardQuery(() {
    final query = service
        .from('appointments')
        .select(
          'id, status, type, scheduled_at, patient:patients!inner(clinic), appointment_doctors(is_active, doctor_id)',
        )
        .gte('scheduled_at', start.toIso8601String())
        .lte('scheduled_at', end.toIso8601String());
    return clinic == null ? query : query.eq('patient.clinic', clinic.dbValue);
  });
}

Future<Map<String, String>> reportDoctorNames(SupabaseService service) async {
  final rows = await service.guardQuery(
    () => service
        .from('staff')
        .select('id, full_name')
        .eq('role', UserRole.doctor.dbValue),
  );
  return {
    for (final row in rows) row['id'] as String: row['full_name'] as String,
  };
}
