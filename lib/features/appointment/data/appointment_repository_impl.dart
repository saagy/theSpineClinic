import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_doctor.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show PostgrestFilterBuilder;

part 'appointment_repository_all_queries.dart';
part 'appointment_repository_base.dart';
part 'appointment_repository_detail_queries.dart';
part 'appointment_repository_mutations.dart';
part 'appointment_repository_patient_queries.dart';
part 'appointment_repository_patient_filters.dart';
part 'appointment_repository_today_queries.dart';

const String _appointmentsTable = 'appointments';
const String _appointmentDoctorsTable = 'appointment_doctors';

/// Supabase-backed implementation of [AppointmentRepository].
class AppointmentRepositoryImpl
    with
        _AppointmentRepositoryBase,
        _TodayAppointmentQueries,
        _PatientAppointmentQueries,
        _PatientAppointmentFilters,
        _AppointmentDetailQueries,
        _AllAppointmentQueries,
        _AppointmentMutations
    implements AppointmentRepository {
  AppointmentRepositoryImpl({required SupabaseService supabaseService})
    : _service = supabaseService;

  @override
  final SupabaseService _service;
}
