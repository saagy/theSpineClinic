import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_doctor.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestFilterBuilder;

import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';

/// Supabase-backed implementation of [AppointmentRepository].
class AppointmentRepositoryImpl implements AppointmentRepository {
  AppointmentRepositoryImpl({required SupabaseService supabaseService}) : _service = supabaseService;
  final SupabaseService _service;

  static const String _appointmentsTable = 'appointments';
  static const String _appointmentDoctorsTable = 'appointment_doctors';

  Future<Result<T>> _run<T>(Future<T> Function() action) async {
    try {
      final res = await _service.guardQuery(action);
      return Result.success(res);
    } on AppException catch (error) {
      return Result.failure(error);
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }

  @override
  Future<Result<List<Appointment>>> getAppointmentsForToday(ClinicLocation clinic) {
    return _run(() async {
      final DateTime localNow = DateTime.now();
      final DateTime todayStart = DateTime(localNow.year, localNow.month, localNow.day).toUtc();
      final DateTime tomorrowStart = todayStart.add(const Duration(days: 1));

      final List<Map<String, dynamic>> rows = await _service.from(_appointmentsTable)
          .select('*, patient:patients!inner(clinic)')
          .eq('patient.clinic', clinic.dbValue)
          .gte('scheduled_at', todayStart.toIso8601String())
          .lt('scheduled_at', tomorrowStart.toIso8601String())
          .order('scheduled_at', ascending: true);
      return rows.map(Appointment.fromJson).toList();
    });
  }

  @override
  Future<Result<List<AppointmentWithPatient>>> getTodayAppointmentsWithPatients(
    ClinicLocation clinic,
  ) {
    return _run(() async {
      final DateTime localNow = DateTime.now();
      final DateTime todayStart =
          DateTime(localNow.year, localNow.month, localNow.day).toUtc();
      final DateTime tomorrowStart = todayStart.add(const Duration(days: 1));

      final List<Map<String, dynamic>> rows = await _service
          .from(_appointmentsTable)
          .select('*, patient:patients!inner(*)')
          .eq('patient.clinic', clinic.dbValue)
          .gte('scheduled_at', todayStart.toIso8601String())
          .lt('scheduled_at', tomorrowStart.toIso8601String())
          .order('scheduled_at', ascending: true);
      return rows.map(_toAppointmentWithPatient).toList();
    });
  }

  @override
  Future<Result<List<AppointmentWithPatient>>> getUpcomingAppointmentsWithPatients(
    ClinicLocation clinic,
  ) {
    return _run(() async {
      final DateTime localNow = DateTime.now();
      final DateTime tomorrowStart = DateTime(
            localNow.year,
            localNow.month,
            localNow.day,
          ).add(const Duration(days: 1)).toUtc();

      final List<Map<String, dynamic>> rows = await _service
          .from(_appointmentsTable)
          .select('*, patient:patients!inner(*)')
          .eq('patient.clinic', clinic.dbValue)
          .gte('scheduled_at', tomorrowStart.toIso8601String())
          .order('scheduled_at', ascending: true);
      return rows.map(_toAppointmentWithPatient).toList();
    });
  }

  AppointmentWithPatient _toAppointmentWithPatient(Map<String, dynamic> row) {
    return AppointmentWithPatient(
      appointment: Appointment.fromJson(row),
      patient: Patient.fromJson(row['patient'] as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<void>> updateAppointmentStatus(String appointmentId, AppointmentStatus status) {
    return _run(() => _service.from(_appointmentsTable).update({'status': status.dbValue}).eq('id', appointmentId));
  }

  @override
  Future<Result<List<AppointmentDoctor>>> getAppointmentDoctors(String appointmentId) {
    return _run(() async {
      final List<Map<String, dynamic>> rows = await _service.from(_appointmentDoctorsTable).select().eq('appointment_id', appointmentId).eq('is_active', true);
      return rows.map(AppointmentDoctor.fromJson).toList();
    });
  }

  @override
  Future<Result<String>> createAppointment(Appointment appointment) {
    return _run(() async {
      final Map<String, dynamic> appointmentJson = appointment.toJson();
      if (appointment.id.isEmpty) appointmentJson.remove('id');
      final Map<String, dynamic> row = await _service.from(_appointmentsTable).insert(appointmentJson).select('id').single();
      return row['id'] as String;
    });
  }

  @override
  Future<Result<void>> createAppointmentDoctor(AppointmentDoctor appointmentDoctor) {
    return _run(() async {
      final Map<String, dynamic> docJson = appointmentDoctor.toJson();
      if (appointmentDoctor.id.isEmpty) docJson.remove('id');
      await _service.from(_appointmentDoctorsTable).insert(docJson);
    });
  }

  @override
  Future<Result<List<Staff>>> getAssignedDoctors(String patientId) {
    return _run(() async {
      final List<Map<String, dynamic>> rows = await _service.from('patient_doctors').select('staff:staff!doctor_id (*)').eq('patient_id', patientId);
      return rows.map((row) {
        final Map<String, dynamic>? staffJson = row['staff'] as Map<String, dynamic>?;
        return staffJson != null ? Staff.fromJson(staffJson) : null;
      }).whereType<Staff>().toList();
    });
  }

  @override
  Future<Result<List<Appointment>>> getAppointmentsForPatient(String patientId) {
    return _run(() async {
      final List<Map<String, dynamic>> rows = await _service.from(_appointmentsTable).select().eq('patient_id', patientId).order('scheduled_at', ascending: true);
      return rows.map(Appointment.fromJson).toList();
    });
  }

  @override
  Future<Result<int>> getFutureScheduledAppointmentsCount(String patientId) {
    return _run(() async {
      final String nowIso = DateTime.now().toUtc().toIso8601String();
      final List<Map<String, dynamic>> rows = await _service.from(_appointmentsTable).select('id')
          .eq('patient_id', patientId)
          .eq('status', 'scheduled')
          .gte('scheduled_at', nowIso);
      return rows.length;
    });
  }

  @override
  Future<Result<Appointment>> getAppointmentById(String appointmentId) {
    return _run(() async {
      final Map<String, dynamic> row = await _service.from(_appointmentsTable).select().eq('id', appointmentId).single();
      return Appointment.fromJson(row);
    });
  }

  @override
  Future<Result<List<AppointmentDoctor>>> getAllAppointmentDoctors(String appointmentId) {
    return _run(() async {
      final List<Map<String, dynamic>> rows = await _service.from(_appointmentDoctorsTable).select().eq('appointment_id', appointmentId);
      return rows.map(AppointmentDoctor.fromJson).toList();
    });
  }

  @override
  Future<Result<List<DoctorScheduleItem>>> getDoctorSchedule(String doctorId) {
    return _run(() async {
      final List<Map<String, dynamic>> rows = await _service
          .from(_appointmentDoctorsTable)
          .select('''
            *,
            appointment:appointments!appointment_id(
              *,
              patient:patients!patient_id(*)
            ),
            replaced_doctor:staff!replaced_doctor_id(*)
          ''')
          .eq('doctor_id', doctorId)
          .eq('is_active', true);

      final List<DoctorScheduleItem> items = [];
      for (final Map<String, dynamic> row in rows) {
        final AppointmentDoctor appointmentDoctor = AppointmentDoctor.fromJson(row);
        final Map<String, dynamic>? appointmentMap = row['appointment'] as Map<String, dynamic>?;
        if (appointmentMap == null) continue;

        final Appointment appointment = Appointment.fromJson(appointmentMap);
        final Map<String, dynamic>? patientMap = appointmentMap['patient'] as Map<String, dynamic>?;
        if (patientMap == null) continue;

        final Patient patient = Patient.fromJson(patientMap);
        final Map<String, dynamic>? replacedDoctorMap = row['replaced_doctor'] as Map<String, dynamic>?;
        final Staff? replacedDoctor = replacedDoctorMap != null ? Staff.fromJson(replacedDoctorMap) : null;

        items.add(DoctorScheduleItem(
          appointment: appointment,
          appointmentDoctor: appointmentDoctor,
          patient: patient,
          replacedDoctor: replacedDoctor,
        ));
      }

      items.sort((a, b) => a.appointment.scheduledAt.compareTo(b.appointment.scheduledAt));
      return items;
    });
  }

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
      final List<String>? doctorIds = await _resolveDoctorIds(doctorId);
      if (doctorIds != null && doctorIds.isEmpty) return <AppointmentWithPatient>[];

      final builder = _applyFilters(
        doctorIds: doctorIds,
        dateFrom: dateFrom,
        dateTo: dateTo,
        status: status,
        clinic: clinic,
        type: type,
        patientQuery: patientQuery,
      );

      final List<Map<String, dynamic>> rows = await builder
          .order('scheduled_at', ascending: ascending)
          .range(offset, offset + limit - 1);
      return rows
          .where((r) => r['patient'] != null)
          .map((r) => AppointmentWithPatient(
                appointment: Appointment.fromJson(r),
                patient: Patient.fromJson(r['patient'] as Map<String, dynamic>),
              ))
          .toList();
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
      final List<String>? doctorIds = await _resolveDoctorIds(doctorId);
      if (doctorIds != null && doctorIds.isEmpty) return 0;

      final builder = _applyFilters(
        doctorIds: doctorIds,
        dateFrom: dateFrom,
        dateTo: dateTo,
        status: status,
        clinic: clinic,
        type: type,
        patientQuery: patientQuery,
      );

      // Use the same inner-join query that getAllAppointments uses,
      // counting rows client-side so the !inner constraint is preserved.
      final List<Map<String, dynamic>> rows = await builder;
      return rows.length;
    });
  }

  /// Resolves appointment IDs for a doctor filter. Returns `null` when no
  /// doctor filter is active, or an empty list when the doctor has no appointments.
  Future<List<String>?> _resolveDoctorIds(String? doctorId) async {
    if (doctorId == null) return null;
    final List<Map<String, dynamic>> rows = await _service
        .from(_appointmentDoctorsTable)
        .select('appointment_id')
        .eq('doctor_id', doctorId)
        .eq('is_active', true);
    return rows.map((r) => r['appointment_id'] as String).toList();
  }

  /// Applies all non-doctor filters to the base query.
  PostgrestFilterBuilder _applyFilters({
    required List<String>? doctorIds,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? status,
    String? clinic,
    String? type,
    String? patientQuery,
  }) {
    var builder = _service.from(_appointmentsTable).select('*, patient:patients!inner(*)');
    if (dateFrom != null) builder = builder.gte('scheduled_at', dateFrom.toUtc().toIso8601String());
    if (dateTo != null) builder = builder.lt('scheduled_at', dateTo.toUtc().toIso8601String());
    if (status != null) builder = builder.eq('status', status);
    if (clinic != null) builder = builder.eq('patient.clinic', clinic);
    if (type != null) builder = builder.eq('type', type);
    if (doctorIds != null) builder = builder.inFilter('id', doctorIds);

    if (patientQuery != null && patientQuery.trim().isNotEmpty) {
      for (final String token in patientQuery.trim().split(RegExp(r'\s+'))) {
        if (token.isNotEmpty) {
          final String escaped = _escapeLike(token);
          builder = builder.or('patient.full_name.ilike.%$escaped%,patient.phone_number.ilike.%$escaped%');
        }
      }
    }
    return builder;
  }

  /// Escapes SQL LIKE metacharacters so user search input is matched literally.
  static String _escapeLike(String value) {
    return value
        .replaceAll('\\', '\\\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
  }
}
