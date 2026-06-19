library;

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/core/utils/patient_helpers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_repository.dart';

/// Supabase-backed implementation of [PatientRepository].
class PatientRepositoryImpl implements PatientRepository {
  /// Creates a [PatientRepositoryImpl].
  PatientRepositoryImpl({required SupabaseService supabaseService}) : _service = supabaseService;

  final SupabaseService _service;
  static const String _table = 'patients';
  static const String _doctorsTable = 'patient_doctors';
  static const int _searchLimit = 50;

  @override
  Future<Result<List<Patient>>> searchPatients({required String query, ClinicLocation? clinic}) async {
    try {
      final String trimmed = query.trim();
      if (trimmed.isEmpty) return const Result.success([]);
      final List<String> tokens = trimmed.split(RegExp(r'\s+'));
      final List<Map<String, dynamic>> rows = await _service.guardQuery(() {
        final base = _service.from(_table).select('*, appointments(scheduled_at, status)');
        final filtered = tokens.where((t) => t.isNotEmpty).fold(base, (q, token) => q.or('full_name.ilike.%$token%,phone_number.ilike.%$token%'));
        final withClinic = clinic != null ? filtered.eq('clinic', clinic.dbValue) : filtered;
        return withClinic.order('full_name').limit(_searchLimit);
      });
      return Result.success(rows.map(_parsePatientRowWithLastAppt).toList());
    } on AppException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }

  @override
  Future<Result<Patient>> getPatientById(String id) async {
    try {
      final Map<String, dynamic> row = await _service.guardQuery(() => _service.from(_table).select('*, appointments(scheduled_at, status)').eq('id', id).single());
      return Result.success(_parsePatientRowWithLastAppt(row));
    } on AppException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }

  @override
  Future<Result<Patient>> createPatient(Patient patient, List<String> assignedDoctorIds) async {
    try {
      final Map<String, dynamic> row = await _service.guardQuery(() => _service.rpc(
        'create_patient_with_doctors',
        params: {
          'p_name': patient.fullName,
          'p_phone': patient.phoneNumber,
          'p_program': patient.program,
          'p_clinic': patient.clinic.dbValue,
          'p_created_by': patient.createdBy,
          'p_doctor_ids': assignedDoctorIds,
        },
      ));
      return Result.success(Patient.fromJson(row));
    } on AppException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }

  @override
  Future<Result<void>> updatePatient(Patient patient) async {
    try {
      final Map<String, dynamic> patientJson = patient.toJson();
      patientJson.remove('id');
      patientJson.remove('created_at');
      await _service.guardQuery(() => _service.from(_table).update(patientJson).eq('id', patient.id));
      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }

  @override
  Future<Result<void>> updatePatientDoctors(String patientId, List<String> currentDoctorIds) async {
    try {
      await _service.guardQuery(() => _service.rpc(
        'update_patient_doctors',
        params: {
          'p_patient_id': patientId,
          'p_doctor_ids': currentDoctorIds,
        },
      ));
      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }

  @override
  Future<Result<bool>> isDoctorAssignedOrCovering({required String patientId, required String doctorId}) async {
    try {
      // 1. Check direct permanent assignment
      final List<Map<String, dynamic>> directRows = await _service.guardQuery(() => _service.from(_doctorsTable).select().eq('patient_id', patientId).eq('doctor_id', doctorId));
      if (directRows.isNotEmpty) return const Result.success(true);

      // 2. Check direct active appointment assignment
      final List<Map<String, dynamic>> apptDocRows = await _service.guardQuery(() => _service
          .from('appointment_doctors')
          .select('doctor_id, appointments!inner(patient_id)')
          .eq('is_active', true)
          .eq('appointments.patient_id', patientId));
      final List<String> apptDoctorIds = apptDocRows.map((r) => r['doctor_id'] as String).toList();
      if (apptDoctorIds.contains(doctorId)) return const Result.success(true);

      // 3. If neither permanent assignment nor active appointment assignment
      //    was found, the doctor has no access to this patient.
      return const Result.success(false);
    } on AppException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }

  @override
  Future<Result<List<Patient>>> getAllPatients({
    String? query,
    String? doctorId,
    ClinicLocation? clinic,
    int offset = 0,
    int limit = 30,
    String orderBy = 'full_name',
    bool ascending = true,
  }) async {
    try {
      final List<Map<String, dynamic>> rows = await _service.guardQuery(() {
        final base = doctorId != null
            ? _service.from(_table).select('*, patient_doctors!inner(), appointments(scheduled_at, status)').eq('patient_doctors.doctor_id', doctorId)
            : _service.from(_table).select('*, appointments(scheduled_at, status)');
        final withClinic = clinic != null ? base.eq('clinic', clinic.dbValue) : base;
        if (query != null && query.trim().isNotEmpty) {
          final tokens = query.trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
          final built = tokens.fold(withClinic, (q, t) => q.or('full_name.ilike.%$t%,phone_number.ilike.%$t%'));
          return built.order(orderBy, ascending: ascending).range(offset, offset + limit - 1);
        }
        return withClinic.order(orderBy, ascending: ascending).range(offset, offset + limit - 1);
      });
      return Result.success(rows.map(_parsePatientRowWithLastAppt).toList());
    } on AppException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }

  @override
  Future<Result<int>> countAllPatients({
    String? query,
    String? doctorId,
    ClinicLocation? clinic,
  }) async {
    try {
      final List<Map<String, dynamic>> rows = await _service.guardQuery(() {
        final base = doctorId != null
            ? _service.from(_table).select('id, patient_doctors!inner(doctor_id)').eq('patient_doctors.doctor_id', doctorId)
            : _service.from(_table).select('id');
        final withClinic = clinic != null ? base.eq('clinic', clinic.dbValue) : base;
        if (query != null && query.trim().isNotEmpty) {
          final tokens = query.trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
          final dynamic queryBuilder = withClinic;
          return tokens.fold<dynamic>(queryBuilder, (q, t) => q.or('full_name.ilike.%$t%,phone_number.ilike.%$t%'));
        }
        return withClinic;
      });
      return Result.success(rows.length);
    } on AppException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }
  /// Builds a [Patient] from a row that includes embedded appointments.
  ///
  /// The DB's `last_appointment_date` column is **always** replaced by the
  /// result of [computeLastAppointmentDate] so every screen shares one
  /// consistent derivation. If the embedded `appointments` key is absent
  /// (e.g. a future query path that forgets to join) we conservatively
  /// preserve whatever the DB column held.
  Patient _parsePatientRowWithLastAppt(Map<String, dynamic> row) {
    final dynamic appts = row['appointments'];
    final Patient patient = Patient.fromJson(row);

    if (appts is! List) return patient; // No join done — keep DB value

    final List<Map<String, dynamic>> apptRows = appts
        .whereType<Map<String, dynamic>>()
        .toList();
    final DateTime? computed = computeLastAppointmentDate(apptRows);
    return patient.copyWith(lastAppointmentDate: computed);
  }
}
