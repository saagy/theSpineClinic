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

      final String pattern = '%$trimmed%';

      // Build the filter query: OR across full_name and phone_number.
      var queryBuilder = _service
          .from(_table)
          .select()
          .or('full_name.ilike.$pattern,phone_number.ilike.$pattern');

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
}
