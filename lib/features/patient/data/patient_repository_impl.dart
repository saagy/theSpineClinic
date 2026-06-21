library;

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/core/utils/patient_helpers.dart';
import 'package:spine_clinic_app/features/patient/data/patient_repository_queries.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_documents_repository.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_repository.dart';

/// Supabase-backed implementation of [PatientRepository].
class PatientRepositoryImpl implements PatientRepository {
  /// Creates a [PatientRepositoryImpl].
  PatientRepositoryImpl({
    required SupabaseService supabaseService,
    required PatientDocumentsRepository documentsRepository,
  })  : _service = supabaseService,
        _documentsRepo = documentsRepository;

  final SupabaseService _service;
  final PatientDocumentsRepository _documentsRepo;
  late final PatientRepositoryQueries _queries = PatientRepositoryQueries(_service);
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
      return Result.success(rows.map(parsePatientRowWithLastAppt).toList());
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
      return Result.success(parsePatientRowWithLastAppt(row));
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
      final List<Map<String, dynamic>> directRows = await _service.guardQuery(() => _service.from(_doctorsTable).select().eq('patient_id', patientId).eq('doctor_id', doctorId));
      if (directRows.isNotEmpty) return const Result.success(true);

      final List<Map<String, dynamic>> apptDocRows = await _service.guardQuery(() => _service
          .from('appointment_doctors')
          .select('doctor_id, appointments!inner(patient_id)')
          .eq('is_active', true)
          .eq('appointments.patient_id', patientId));
      final List<String> apptDoctorIds = apptDocRows.map((r) => r['doctor_id'] as String).toList();
      if (apptDoctorIds.contains(doctorId)) return const Result.success(true);

      return const Result.success(false);
    } on AppException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }

  // ── Delegated to PatientRepositoryQueries ──

  @override
  Future<Result<List<Patient>>> getAllPatients({
    String? query,
    String? doctorId,
    ClinicLocation? clinic,
    int offset = 0,
    int limit = 30,
    String orderBy = 'full_name',
    bool ascending = true,
  }) {
    return _queries.getAllPatients(
      query: query,
      doctorId: doctorId,
      clinic: clinic,
      offset: offset,
      limit: limit,
      orderBy: orderBy,
      ascending: ascending,
    );
  }

  @override
  Future<Result<int>> countAllPatients({
    String? query,
    String? doctorId,
    ClinicLocation? clinic,
  }) {
    return _queries.countAllPatients(
      query: query,
      doctorId: doctorId,
      clinic: clinic,
    );
  }

  // ── Patient deletion ──

  @override
  Future<Result<bool>> isPatientEmpty(String patientId) async {
    try {
      final results = await Future.wait([
        _service.guardQuery(() => _service.from('appointments').select('id').eq('patient_id', patientId).limit(1)),
        _service.guardQuery(() => _service.from('payment_records').select('id').eq('patient_id', patientId).limit(1)),
        _service.guardQuery(() => _service.from('patient_notes').select('id').eq('patient_id', patientId).limit(1)),
        _service.guardQuery(() => _service.from('patient_documents').select('id').eq('patient_id', patientId).limit(1)),
      ]);
      final bool isEmpty = results.every((r) => (r as List).isEmpty);
      return Result.success(isEmpty);
    } on AppException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }

  @override
  Future<Result<void>> deletePatient(String patientId) async {
    try {
      // Safety-net: sweep the patient's storage folder BEFORE the DB
      // row delete. The UI guard `isPatientEmpty` should already
      // prevent this running with active documents, but this catches
      // orphaned blobs from earlier upload failures.
      await _documentsRepo.deletePatientStorageFolder(patientId);
      await _service.guardQuery(() => _service.from(_table).delete().eq('id', patientId));
      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }
}
