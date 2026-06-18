import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
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
  /// Skips the doctor assignment RPC when [initialDoctorIds] matches
  /// [selectedDoctorIds] to avoid an unnecessary delete+insert cycle.
  /// Returns `true` if update succeeds, `false` otherwise.
  Future<bool> submit({
    required Patient patient,
    required List<String> selectedDoctorIds,
    required List<String> initialDoctorIds,
  }) async {
    state = const AsyncValue.loading();
    final repo = ref.read(patientRepositoryProvider);

    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      state = AsyncValue.error(
        const AuthException(
          code: 'auth/unauthorized',
          message: 'User must be authenticated to edit patient info.',
          userMessageKey: 'error_auth_generic',
        ),
        StackTrace.current,
      );
      return false;
    }

    if (currentUser.role == UserRole.doctor) {
      final Result<bool> isAssignedResult = await repo.isDoctorAssignedOrCovering(
        patientId: patient.id,
        doctorId: currentUser.id,
      );
      if (!ref.mounted) return false;

      final bool isAssigned = isAssignedResult.when(
        success: (val) => val,
        failure: (_) => false,
      );

      if (!isAssigned) {
        state = AsyncValue.error(
          const DatabaseException(
            code: 'db/rls-violation',
            message: 'Doctors can only edit info for their assigned or replacement patients.',
            userMessageKey: 'error_database_permission_denied',
          ),
          StackTrace.current,
        );
        return false;
      }
    }

    // 1. Update patient core fields
    final Result<void> patientResult = await repo.updatePatient(patient);
    if (!ref.mounted) return false;
    if (patientResult is Failure<void>) {
      state = AsyncValue.error(patientResult.exception, StackTrace.current);
      return false;
    }

    // 2. Update patient doctor assignments (only for admin/receptionist,
    //    and only when the list has actually changed)
    if (currentUser.role != UserRole.doctor) {
      final currentSet = selectedDoctorIds.toSet();
      final initialSet = initialDoctorIds.toSet();
      final doctorsChanged = currentSet.length != initialSet.length ||
          !currentSet.every(initialSet.contains);

      if (doctorsChanged) {
        final Result<void> doctorsResult = await repo.updatePatientDoctors(
          patient.id,
          selectedDoctorIds,
        );
        if (!ref.mounted) return false;
        if (doctorsResult is Failure<void>) {
          state = AsyncValue.error(doctorsResult.exception, StackTrace.current);
          return false;
        }
      }
    }

    // Invalidate detail data upstream to refresh presentation layer
    ref.invalidate(patientDetailProvider(patient.id));
    ref.invalidate(patientAssignedDoctorsProvider(patient.id));
    ref.invalidate(patientSearchProvider);

    state = const AsyncValue.data(null);
    return true;
  }
}
