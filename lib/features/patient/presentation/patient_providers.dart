/// Riverpod providers for the patient search feature.
///
/// [patientRepositoryProvider] — singleton repository access.
/// [patientSearchProvider] — code-generated async notifier managing
/// the current search query, clinic filter, and result list.
///
/// Rule 3 — all state via Riverpod.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/patient/data/patient_repository_impl.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_repository.dart';

part 'patient_providers.g.dart';

/// Provides a singleton [PatientRepository] instance.
@Riverpod(keepAlive: true)
PatientRepository patientRepository(Ref ref) {
  return PatientRepositoryImpl(
    supabaseService: SupabaseService.instance,
  );
}

/// Fetches a single patient record by its ID using the repository.
@riverpod
Future<Patient> patientDetail(Ref ref, String id) async {
  final PatientRepository repo = ref.read(patientRepositoryProvider);
  final Result<Patient> result = await repo.getPatientById(id);
  return result.when(
    success: (Patient data) => data,
    failure: (AppException exception) => throw exception,
  );
}

/// Async notifier that manages patient search state.
///
/// Tracks the current query and clinic filter. When [search] is called,
/// the notifier sets loading → executes the repository query → sets
/// data or error. The Supabase RLS policies enforce role-scoped
/// filtering transparently.
@riverpod
class PatientSearch extends _$PatientSearch {
  @override
  Future<List<Patient>> build() async {
    return [];
  }

  /// Executes a patient search with the given [query] and optional [clinic].
  ///
  /// Empty queries return an empty list without hitting the database.
  Future<void> search(String query, {ClinicLocation? clinic}) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();

    final PatientRepository repo = ref.read(patientRepositoryProvider);
    final Result<List<Patient>> result = await repo.searchPatients(
      query: query,
      clinic: clinic,
    );

    result.when(
      success: (List<Patient> data) => state = AsyncValue.data(data),
      failure: (error) => state = AsyncValue.error(error, StackTrace.current),
    );
  }

  /// Resets the search state to an empty list.
  void clear() {
    state = const AsyncValue.data([]);
  }
}
