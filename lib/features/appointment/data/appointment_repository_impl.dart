import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/appointment/data/appointment_repository_recent_access.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_doctor.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
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
  Future<Result<List<Appointment>>> getAppointmentsForToday(ClinicLocation? clinic) {
    return _run(() async {
      final DateTime localNow = DateTime.now();
      final DateTime todayStart = DateTime(localNow.year, localNow.month, localNow.day).toUtc();
      final DateTime tomorrowStart = todayStart.add(const Duration(days: 1));

      var query = _service.from(_appointmentsTable)
          .select('*, patient:patients!inner(clinic)');
      if (clinic != null) {
        query = query.eq('patient.clinic', clinic.dbValue);
      }
      final List<Map<String, dynamic>> rows = await query
          .gte('scheduled_at', todayStart.toIso8601String())
          .lt('scheduled_at', tomorrowStart.toIso8601String())
          .order('scheduled_at', ascending: true);
      return rows.map(Appointment.fromJson).toList();
    });
  }

  @override
  Future<Result<List<AppointmentWithPatient>>> getTodayAppointmentsWithPatients(
    ClinicLocation? clinic,
  ) {
    return _run(() async {
      final DateTime localNow = DateTime.now();
      final DateTime todayStart =
          DateTime(localNow.year, localNow.month, localNow.day).toUtc();
      final DateTime tomorrowStart = todayStart.add(const Duration(days: 1));

      var query = _service
          .from(_appointmentsTable)
          .select('*, patient:patients!inner(*)');
      if (clinic != null) {
        query = query.eq('patient.clinic', clinic.dbValue);
      }
      final List<Map<String, dynamic>> rows = await query
          .gte('scheduled_at', todayStart.toIso8601String())
          .lt('scheduled_at', tomorrowStart.toIso8601String())
          .order('scheduled_at', ascending: true);
      return rows.map(_toAppointmentWithPatient).toList();
    });
  }

  @override
  Future<Result<List<AppointmentWithPatient>>> getUpcomingAppointmentsWithPatients(
    ClinicLocation? clinic,
  ) {
    return _run(() async {
      final DateTime localNow = DateTime.now();
      final DateTime tomorrowStart = DateTime(
            localNow.year,
            localNow.month,
            localNow.day,
          ).add(const Duration(days: 1)).toUtc();

      var query = _service
          .from(_appointmentsTable)
          .select('*, patient:patients!inner(*)');
      if (clinic != null) {
        query = query.eq('patient.clinic', clinic.dbValue);
      }
      final List<Map<String, dynamic>> rows = await query
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
      final List<Map<String, dynamic>> rows = await _service.from('patient_doctors')
          .select('staff:staff!doctor_id (*)')
          .eq('patient_id', patientId);
      // Returns ALL assigned doctors regardless of active status.
      // Consumers that need active-only filtering (e.g. appointment booking
      // pre-fill) apply the filter at their own level.
      return rows
          .map((row) {
            final Map<String, dynamic>? staffJson =
                row['staff'] as Map<String, dynamic>?;
            return staffJson != null ? Staff.fromJson(staffJson) : null;
          })
          .whereType<Staff>()
          .toList();
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
  Future<Result<List<Appointment>>> getAppointmentsForPatientPaginated({
    required String patientId,
    int offset = 0,
    int limit = 30,
    Set<AppointmentStatus>? statusFilter,
    Set<AppointmentType>? typeFilter,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? doctorId,
    bool? usePackageFilter,
    bool ascending = false,
  }) {
    return _run(() async {
      final List<String>? doctorIds = await _resolveDoctorIds(doctorId);
      if (doctorIds != null && doctorIds.isEmpty) return <Appointment>[];

      final builder = _applyPatientFilters(
        patientId: patientId,
        doctorIds: doctorIds,
        statusFilter: statusFilter,
        typeFilter: typeFilter,
        dateFrom: dateFrom,
        dateTo: dateTo,
        usePackageFilter: usePackageFilter,
      );

      final List<Map<String, dynamic>> rows = await builder
          .order('scheduled_at', ascending: ascending)
          .range(offset, offset + limit - 1);
      return rows.map(Appointment.fromJson).toList();
    });
  }

  @override
  Future<Result<int>> countAppointmentsForPatient({
    required String patientId,
    Set<AppointmentStatus>? statusFilter,
    Set<AppointmentType>? typeFilter,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? doctorId,
    bool? usePackageFilter,
  }) {
    return _run(() async {
      final List<String>? doctorIds = await _resolveDoctorIds(doctorId);
      if (doctorIds != null && doctorIds.isEmpty) return 0;

      final builder = _applyPatientFilters(
        patientId: patientId,
        doctorIds: doctorIds,
        statusFilter: statusFilter,
        typeFilter: typeFilter,
        dateFrom: dateFrom,
        dateTo: dateTo,
        usePackageFilter: usePackageFilter,
      );

      final List<Map<String, dynamic>> rows = await builder;
      return rows.length;
    });
  }

  PostgrestFilterBuilder _applyPatientFilters({
    required String patientId,
    required List<String>? doctorIds,
    Set<AppointmentStatus>? statusFilter,
    Set<AppointmentType>? typeFilter,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool? usePackageFilter,
  }) {
    var builder = _service.from(_appointmentsTable).select().eq('patient_id', patientId);
    if (dateFrom != null) {
      builder = builder.gte('scheduled_at', dateFrom.toUtc().toIso8601String());
    }
    if (dateTo != null) {
      builder = builder.lt('scheduled_at', dateTo.toUtc().toIso8601String());
    }
    if (statusFilter != null && statusFilter.isNotEmpty) {
      builder = builder.inFilter('status', statusFilter.map((s) => s.dbValue).toList());
    }
    if (typeFilter != null && typeFilter.isNotEmpty) {
      builder = builder.inFilter('type', typeFilter.map((t) => t.dbValue).toList());
    }
    if (usePackageFilter != null) {
      builder = builder.eq('use_package', usePackageFilter);
    }
    if (doctorIds != null) {
      builder = builder.inFilter('id', doctorIds);
    }
    return builder;
  }

  @override
  Future<Result<int>> getFutureScheduledAppointmentsCount(String patientId) {
    return _run(() async {
      final String nowIso = DateTime.now().toUtc().toIso8601String();
      final List<Map<String, dynamic>> rows = await _service
          .from(_appointmentsTable)
          .select('id')
          .eq('patient_id', patientId)
          .eq('status', 'scheduled')
          .eq('use_package', true)
          .gte('scheduled_at', nowIso);
      return rows.length;
    });
  }

  @override
  Future<Result<int>> getFutureScheduledAppointmentsCountForType({
    required String patientId,
    required AppointmentType type,
  }) {
    if (!type.affectsPackageBalance) {
      return Future.value(const Result.success(0));
    }
    return _run(() async {
      final String nowIso = DateTime.now().toUtc().toIso8601String();
      final List<Map<String, dynamic>> rows = await _service
          .from(_appointmentsTable)
          .select('id')
          .eq('patient_id', patientId)
          .eq('status', 'scheduled')
          .eq('use_package', true)
          .eq('type', type.dbValue)
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
          builder = builder.or(
            'full_name.ilike.%$escaped%,phone_number.ilike.%$escaped%',
            referencedTable: 'patients',
          );
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

  @override
  Future<Result<void>> updateAppointment(Appointment appointment) {
    return _run(() => _service
        .from(_appointmentsTable)
        .update({
          'scheduled_at': appointment.scheduledAt.toIso8601String(),
          'type': appointment.type.dbValue,
          'use_package': appointment.usePackage,
        })
        .eq('id', appointment.id));
  }

  @override
  Future<Result<void>> deleteAppointment(String appointmentId) {
    return _run(() => _service
        .from(_appointmentsTable)
        .delete()
        .eq('id', appointmentId));
  }

  @override
  Future<Result<void>> updateAppointmentDoctors(
    String appointmentId,
    List<String> doctorIds,
    String? editorId,
  ) {
    return _run(() async {
      // 1. Fetch all doctor assignments (active and inactive) for this appointment
      final List<Map<String, dynamic>> allRows = await _service
          .from(_appointmentDoctorsTable)
          .select()
          .eq('appointment_id', appointmentId);
      
      final List<String> currentActiveDoctorIds = allRows
          .where((row) => row['is_active'] as bool == true)
          .map((row) => row['doctor_id'] as String)
          .toList();

      final List<String> currentInactiveDoctorIds = allRows
          .where((row) => row['is_active'] as bool == false)
          .map((row) => row['doctor_id'] as String)
          .toList();

      // 2. Identify doctor IDs to deactivate: in current active but not in new doctorIds
      final List<String> toDeactivate = currentActiveDoctorIds
          .where((id) => !doctorIds.contains(id))
          .toList();

      // 3. Identify doctor IDs to reactivate: in new doctorIds and in current inactive
      final List<String> toReactivate = doctorIds
          .where((id) => currentInactiveDoctorIds.contains(id))
          .toList();

      // 4. Identify doctor IDs to insert: in new doctorIds but not in active or inactive lists
      final List<String> toInsert = doctorIds
          .where((id) => !currentActiveDoctorIds.contains(id) && !currentInactiveDoctorIds.contains(id))
          .toList();

      // 5. Perform deactivations (set is_active = false)
      if (toDeactivate.isNotEmpty) {
        await _service
            .from(_appointmentDoctorsTable)
            .update({'is_active': false})
            .eq('appointment_id', appointmentId)
            .inFilter('doctor_id', toDeactivate);
      }

      // 6. Perform reactivations (set is_active = true and update added audit info)
      if (toReactivate.isNotEmpty) {
        await _service
            .from(_appointmentDoctorsTable)
            .update({
              'is_active': true,
              'added_by': editorId,
              'added_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('appointment_id', appointmentId)
            .inFilter('doctor_id', toReactivate);
      }

      // 7. Perform insertions (insert new rows with is_active = true)
      if (toInsert.isNotEmpty) {
        final List<Map<String, dynamic>> rowsToInsert = toInsert.map((doctorId) {
          return {
            'appointment_id': appointmentId,
            'doctor_id': doctorId,
            'is_replacement': false,
            'is_active': true,
            'added_by': editorId,
            'added_at': DateTime.now().toUtc().toIso8601String(),
          };
        }).toList();

        await _service.from(_appointmentDoctorsTable).insert(rowsToInsert);
      }
    });
  }

  @override
  Future<Result<void>> createRecurringBookings({
    required String patientId,
    required AppointmentType type,
    required List<DateTime> slots,
    required bool usePackage,
    required String? creatorId,
    required List<String> doctorIds,
  }) {
    return _run(() async {
      await _service.rpc('book_recurring_appointments', params: {
        'p_patient_id': patientId,
        'p_type': type.dbValue,
        'p_slots': slots.map((s) => s.toUtc().toIso8601String()).toList(),
        'p_use_package': type.affectsPackageBalance ? usePackage : false,
        'p_creator_id': creatorId,
        'p_doctor_ids': doctorIds,
      });
    });
  }

  @override
  Future<Result<bool>> hasDoctorRecentAppointmentWithPatient({
    required String patientId,
    required String doctorId,
  }) {
    return checkRecentDoctorPatientAppointment(
      service: _service,
      patientId: patientId,
      doctorId: doctorId,
    );
  }
}
