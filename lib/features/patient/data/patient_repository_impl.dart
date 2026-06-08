/// Data-layer implementation of [PatientRepository] backed by Supabase.
///
/// All raw Supabase exceptions are caught and normalised into
/// [AppException] subtypes before wrapping in [Result].
///
/// RLS policies enforce role-scoped visibility at the database level
/// (AGENT_CONTEXT §10). No client-side role filtering is needed.
///
/// Rule 2 — no Supabase calls inside widgets; all access here.
/// Rule 4 — every method returns `Result<T>`.
library;

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_repository.dart';

/// Supabase-backed [PatientRepository].
class PatientRepositoryImpl implements PatientRepository {
  /// Creates a [PatientRepositoryImpl].
  PatientRepositoryImpl({required SupabaseService supabaseService})
      : _service = supabaseService;

  final SupabaseService _service;

  /// Table name constant — avoids magic strings in queries.
  static const String _table = 'patients';

  /// Junction table name constant for patient-doctor assignments.
  static const String _doctorsTable = 'patient_doctors';

  /// Maximum number of search results to return per query.
  static const int _searchLimit = 50;

  @override
  Future<Result<List<Patient>>> searchPatients({
    required String query,
    ClinicLocation? clinic,
  }) async {
    try {
      final String trimmed = query.trim();
      if (trimmed.isEmpty) {
        return const Result.success([]);
      }

      final List<String> tokens = trimmed.split(RegExp(r'\s+'));

      // Build the filter query: AND across all tokens, where each token matches full_name OR phone_number
      var queryBuilder = _service.from(_table).select();

      for (final String token in tokens) {
        if (token.isNotEmpty) {
          final String pattern = '%$token%';
          queryBuilder = queryBuilder.or(
            'full_name.ilike.$pattern,phone_number.ilike.$pattern',
          );
        }
      }

      // Apply optional clinic filter.
      if (clinic != null) {
        queryBuilder = queryBuilder.eq('clinic', clinic.dbValue);
      }

      final List<Map<String, dynamic>> rows = await _service.guardQuery(
        () => queryBuilder.order('full_name').limit(_searchLimit),
      );

      final List<Patient> patients =
          rows.map(Patient.fromJson).toList();
      return Result.success(patients);
    } on AppException catch (error) {
      return Result.failure(error);
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }

  @override
  Future<Result<Patient>> getPatientById(String id) async {
    try {
      final Map<String, dynamic> row = await _service.guardQuery(
        () => _service.from(_table).select().eq('id', id).single(),
      );
      return Result.success(Patient.fromJson(row));
    } on AppException catch (error) {
      return Result.failure(error);
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }

  @override
  Future<Result<Patient>> createPatient(
    Patient patient,
    List<String> assignedDoctorIds,
  ) async {
    try {
      final Map<String, dynamic> patientJson = patient.toJson();
      if (patient.id.isEmpty) {
        patientJson.remove('id');
      }

      // 1. Insert patient and retrieve the generated patient row
      final Map<String, dynamic> row = await _service.guardQuery(
        () => _service.from(_table).insert(patientJson).select().single(),
      );
      final Patient createdPatient = Patient.fromJson(row);

      // 2. Insert junction table records for assigned doctors
      for (final String doctorId in assignedDoctorIds) {
        await _service.guardQuery(
          () => _service.from(_doctorsTable).insert({
            'patient_id': createdPatient.id,
            'doctor_id': doctorId,
          }),
        );
      }

      return Result.success(createdPatient);
    } on AppException catch (error) {
      return Result.failure(error);
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }

  @override
  Future<Result<void>> updatePatient(Patient patient) async {
    try {
      final Map<String, dynamic> patientJson = patient.toJson();
      patientJson.remove('id');
      patientJson.remove('created_at');

      await _service.guardQuery(
        () => _service.from(_table).update(patientJson).eq('id', patient.id),
      );
      return const Result.success(null);
    } on AppException catch (error) {
      return Result.failure(error);
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }

  @override
  Future<Result<void>> updatePatientDoctors(
    String patientId,
    List<String> currentDoctorIds,
  ) async {
    try {
      // 1. Fetch current doctor assignments
      final List<Map<String, dynamic>> rows = await _service.guardQuery(
        () => _service
            .from(_doctorsTable)
            .select('doctor_id')
            .eq('patient_id', patientId),
      );
      final Set<String> existingDoctorIds =
          rows.map((row) => row['doctor_id'] as String).toSet();

      // 2. Compute diff using Set operations
      final Set<String> targetDoctorIds = currentDoctorIds.toSet();
      final Set<String> toDelete = existingDoctorIds.difference(targetDoctorIds);
      final Set<String> toInsert = targetDoctorIds.difference(existingDoctorIds);

      // 3. Execute deletes
      for (final String doctorId in toDelete) {
        await _service.guardQuery(
          () => _service
              .from(_doctorsTable)
              .delete()
              .eq('patient_id', patientId)
              .eq('doctor_id', doctorId),
        );
      }

      // 4. Execute inserts
      for (final String doctorId in toInsert) {
        await _service.guardQuery(
          () => _service.from(_doctorsTable).insert({
            'patient_id': patientId,
            'doctor_id': doctorId,
          }),
        );
      }

      return const Result.success(null);
    } on AppException catch (error) {
      return Result.failure(error);
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }
}

