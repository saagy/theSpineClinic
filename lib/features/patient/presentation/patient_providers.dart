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
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
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

/// Fetches all active/approved staff members with the role of doctor.
@riverpod
Future<List<Staff>> activeDoctors(Ref ref) async {
  final PatientRepository repo = ref.read(patientRepositoryProvider);
  final Result<List<Staff>> result = await repo.getActiveDoctors();
  return result.when(
    success: (List<Staff> data) => data,
    failure: (AppException exception) => throw exception,
  );
}

/// Fetches active doctors assigned to a patient.
@riverpod
Future<List<Staff>> patientAssignedDoctors(Ref ref, String patientId) async {
  final repo = ref.read(appointmentRepositoryProvider);
  final result = await repo.getAssignedDoctors(patientId);
  return result.when(
    success: (List<Staff> data) => data,
    failure: (AppException exception) => throw exception,
  );
}

/// Controller managing the roster of patients assigned to the logged-in doctor.
@riverpod
class MyPatientsController extends _$MyPatientsController {
  @override
  Future<List<Patient>> build() async {
    final Staff? user = ref.watch(currentUserProvider).value;
    if (user == null) return const [];
    final PatientRepository repo = ref.read(patientRepositoryProvider);
    final Result<List<Patient>> result = await repo.getAssignedPatients(doctorId: user.id);
    return result.when(
      success: (List<Patient> data) => data,
      failure: (AppException exception) => throw exception,
    );
  }

  /// Searches assigned patients by name or phone number.
  Future<void> search(String query) async {
    final Staff? user = ref.read(currentUserProvider).value;
    if (user == null) return;
    state = const AsyncValue.loading();
    final PatientRepository repo = ref.read(patientRepositoryProvider);
    final Result<List<Patient>> result = await repo.getAssignedPatients(
      doctorId: user.id,
      query: query,
    );
    result.when(
      success: (List<Patient> data) => state = AsyncValue.data(data),
      failure: (AppException exception) => state = AsyncValue.error(exception, StackTrace.current),
    );
  }
}

/// State representation for the coverage view of replacement patients.
class ReplacementPatientsState {
  /// The list of patients covered.
  final List<Patient> patients;

  /// The list of absent doctors being covered.
  final List<Staff> absentDoctors;

  /// A mapping from patient ID to the absent doctor's name.
  final Map<String, String> patientDoctorMap;

  /// Creates a [ReplacementPatientsState].
  const ReplacementPatientsState({
    required this.patients,
    required this.absentDoctors,
    required this.patientDoctorMap,
  });
}

/// Controller managing replacement patients the doctor can access today.
@riverpod
class ReplacementPatientsController extends _$ReplacementPatientsController {
  @override
  Future<ReplacementPatientsState> build() async {
    final Staff? user = ref.watch(currentUserProvider).value;
    if (user == null) {
      return const ReplacementPatientsState(
        patients: [],
        absentDoctors: [],
        patientDoctorMap: {},
      );
    }
    return _fetch(user.id, null);
  }

  Future<ReplacementPatientsState> _fetch(String doctorId, String? query) async {
    final PatientRepository repo = ref.read(patientRepositoryProvider);

    // 1. Fetch active replacements today
    final Result<List<Staff>> doctorsResult =
        await repo.getActiveReplacementsForDoctor(doctorId: doctorId);
    final List<Staff> absentDoctors = doctorsResult.when(
      success: (List<Staff> data) => data,
      failure: (AppException exception) => throw exception,
    );

    if (absentDoctors.isEmpty) {
      return const ReplacementPatientsState(
        patients: [],
        absentDoctors: [],
        patientDoctorMap: {},
      );
    }

    // 2. Fetch replacement patients
    final Result<List<Patient>> patientsResult =
        await repo.getReplacementPatients(doctorId: doctorId, query: query);
    final List<Patient> patients = patientsResult.when(
      success: (List<Patient> data) => data,
      failure: (AppException exception) => throw exception,
    );

    // 3. Fetch patient-doctor mapping
    final List<String> absentIds = absentDoctors.map((d) => d.id).toList();
    final Result<Map<String, String>> mappingResult =
        await repo.getPatientReplacementMapping(absentDoctorIds: absentIds);
    final Map<String, String> mapping = mappingResult.when(
      success: (Map<String, String> data) => data,
      failure: (AppException exception) => throw exception,
    );

    return ReplacementPatientsState(
      patients: patients,
      absentDoctors: absentDoctors,
      patientDoctorMap: mapping,
    );
  }

  /// Searches replacement patients by name or phone number.
  Future<void> search(String query) async {
    final Staff? user = ref.read(currentUserProvider).value;
    if (user == null) return;
    state = const AsyncValue.loading();
    try {
      final ReplacementPatientsState data = await _fetch(user.id, query);
      state = AsyncValue.data(data);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
