library;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/medical_history_repository.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_medical_history.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/medical_history_providers.dart';

part 'medical_history_controller.g.dart';

/// Controller managing medical history mutations.
@Riverpod(keepAlive: true)
class MedicalHistoryController extends _$MedicalHistoryController {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// Saves or updates the medical history for a patient.
  Future<Result<PatientMedicalHistory>> saveMedicalHistory(
    PatientMedicalHistory history,
  ) async {
    state = const AsyncValue.loading();

    // Rule 6: Read role/permissions and verify before write
    final Staff? user = ref.read(currentUserProvider).value;
    if (user == null) {
      final error = const AuthException(
        code: 'auth/unauthorized',
        message: 'Must be authenticated to update medical history.',
        userMessageKey: 'error_auth_generic',
      );
      state = AsyncValue.error(error, StackTrace.current);
      return Result.failure(error);
    }

    final MedicalHistoryRepository repo =
        ref.read(medicalHistoryRepositoryProvider);
    final historyToSave = history.copyWith(
      updatedBy: user.id,
      updatedAt: DateTime.now().toUtc(),
    );

    final Result<PatientMedicalHistory> result =
        await repo.upsertMedicalHistory(historyToSave);

    if (!ref.mounted) return result;

    result.when(
      success: (PatientMedicalHistory saved) {
        state = const AsyncValue.data(null);
        ref
            .read(patientMedicalHistoryProvider(history.patientId).notifier)
            .updateData(saved);
      },
      failure: (AppException exception) {
        state = AsyncValue.error(exception, StackTrace.current);
      },
    );

    return result;
  }
}
