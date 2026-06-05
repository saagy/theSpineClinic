import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';

part 'edit_patient_controller.g.dart';

/// Riverpod presentation controller coordinating patient updates.
///
/// Inherits AsyncNotifier to represent transaction lifecycle: loading, success, error.
@riverpod
class EditPatientController extends _$EditPatientController {
  @override
  FutureOr<void> build() {
    // Initial state is idle.
  }

  /// Submits the patient updates and assigned doctor junction changes.
  ///
  /// Invokes repository methods sequentially and invalidates detail caches on success.
  /// Returns `true` if update succeeds, `false` otherwise.
  Future<bool> submit({
    required Patient patient,
    required List<String> selectedDoctorIds,
  }) async {
    state = const AsyncValue.loading();
    final repo = ref.read(patientRepositoryProvider);

    // 1. Update patient core fields
    final Result<void> patientResult = await repo.updatePatient(patient);
    if (patientResult is Failure<void>) {
      state = AsyncValue.error(patientResult.exception, StackTrace.current);
      return false;
    }

    // 2. Update patient doctor assignments
    final Result<void> doctorsResult = await repo.updatePatientDoctors(
      patient.id,
      selectedDoctorIds,
    );
    if (doctorsResult is Failure<void>) {
      state = AsyncValue.error(doctorsResult.exception, StackTrace.current);
      return false;
    }

    // Invalidate detail data upstream to refresh presentation layer
    ref.invalidate(patientDetailProvider(patient.id));
    ref.invalidate(patientAssignedDoctorsProvider(patient.id));
    ref.invalidate(patientSearchProvider);

    state = const AsyncValue.data(null);
    return true;
  }
}
