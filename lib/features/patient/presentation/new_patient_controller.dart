import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';

part 'new_patient_controller.g.dart';

/// Notifier provider handling form submission states for NewPatientScreen.
@riverpod
class NewPatientController extends _$NewPatientController {
  @override
  FutureOr<void> build() {
    // Initial state is idle (AsyncData(null))
  }

  /// Registers a new patient and assigns doctors.
  ///
  /// Maps inputs to the [Patient] entity, populates `createdBy` using
  /// the active receptionist/admin user ID, and invokes the repository.
  /// On success, invalidates the search provider to clear stale lists.
  Future<Result<Patient>> createPatient({
    required String fullName,
    required String phoneNumber,
    required String? program,
    required ClinicLocation clinic,
    required List<String> assignedDoctorIds,
  }) async {
    state = const AsyncValue.loading();
    final patientRepo = ref.read(patientRepositoryProvider);
    final currentUser = ref.read(currentUserProvider).value;

    final patient = Patient(
      id: '', // Handled by database auto-generate
      fullName: fullName,
      phoneNumber: phoneNumber,
      program: program?.trim().isEmpty == true ? null : program,
      clinic: clinic,
      packageBalance: 0,
      createdBy: currentUser?.id,
      createdAt: DateTime.now(),
    );

    final Result<Patient> result =
        await patientRepo.createPatient(patient, assignedDoctorIds);

    state = result.when(
      success: (createdPatient) {
        ref.invalidate(patientSearchProvider);
        return const AsyncValue.data(null);
      },
      failure: (error) => AsyncValue.error(error, StackTrace.current),
    );

    return result;
  }
}
