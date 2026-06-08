/// Riverpod providers for the staff and replacement patient controllers.
///
/// Exposes:
/// - [staffRepositoryProvider] — singleton repository access.
/// - [activeDoctorsProvider] — active doctors (includes super admins).
/// - [MyPatientsController] — patients assigned to the current doctor.
/// - [ReplacementPatientsController] — replacement patients for covering doctor today.
///
/// Rule 3 — all state via Riverpod.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/staff/data/staff_repository.dart';

part 'staff_providers.g.dart';

/// Provides a singleton [StaffRepository] instance.
@Riverpod(keepAlive: true)
StaffRepository staffRepository(Ref ref) {
  return StaffRepositoryImpl(
    supabaseService: SupabaseService.instance,
  );
}

/// Fetches all active/approved staff members with the role of doctor or super admin.
@riverpod
Future<List<Staff>> activeDoctors(Ref ref) async {
  final StaffRepository repo = ref.read(staffRepositoryProvider);
  final Result<List<Staff>> result = await repo.getActiveDoctors();
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
    final StaffRepository repo = ref.read(staffRepositoryProvider);
    final Result<List<Patient>> result =
        await repo.getAssignedPatients(doctorId: user.id);
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
    final StaffRepository repo = ref.read(staffRepositoryProvider);
    final Result<List<Patient>> result = await repo.getAssignedPatients(
      doctorId: user.id,
      query: query,
    );
    result.when(
      success: (List<Patient> data) => state = AsyncValue.data(data),
      failure: (AppException exception) =>
          state = AsyncValue.error(exception, StackTrace.current),
    );
  }
}

/// State representation for the coverage view of replacement patients.
class ReplacementPatientsState {
  final List<Patient> patients;
  final List<Staff> absentDoctors;
  final Map<String, String> patientDoctorMap;

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

  Future<ReplacementPatientsState> _fetch(
    String doctorId,
    String? query,
  ) async {
    final StaffRepository repo = ref.read(staffRepositoryProvider);

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
