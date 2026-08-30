library;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/medical_records/data/medical_history_repository_impl.dart';
import 'package:spine_clinic_app/features/medical_records/domain/medical_history_repository.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_medical_history.dart';

part 'medical_history_providers.g.dart';

/// Provides a singleton instance of [MedicalHistoryRepository].
@Riverpod(keepAlive: true)
MedicalHistoryRepository medicalHistoryRepository(Ref ref) {
  return MedicalHistoryRepositoryImpl(
    supabaseService: SupabaseService.instance,
  );
}

/// Fetches and reactively manages medical history for a specific patient.
@riverpod
class PatientMedicalHistoryNotifier extends _$PatientMedicalHistoryNotifier {
  @override
  FutureOr<PatientMedicalHistory?> build(String patientId) async {
    final MedicalHistoryRepository repo =
        ref.watch(medicalHistoryRepositoryProvider);
    final Result<PatientMedicalHistory?> result =
        await repo.getMedicalHistory(patientId);
    return result.when(
      success: (PatientMedicalHistory? data) => data,
      failure: (AppException exception) => throw exception,
    );
  }

  /// Updates medical history in-place immediately without flashing loading state.
  void updateData(PatientMedicalHistory? data) {
    state = AsyncValue.data(data);
  }

  /// Refreshes medical history silently from the server.
  Future<void> refresh() async {
    final MedicalHistoryRepository repo =
        ref.read(medicalHistoryRepositoryProvider);
    final Result<PatientMedicalHistory?> result =
        await repo.getMedicalHistory(patientId);
    if (!ref.mounted) return;
    result.when(
      success: (PatientMedicalHistory? data) {
        state = AsyncValue.data(data);
      },
      failure: (AppException exception) {
        if (!state.hasValue) {
          state = AsyncValue.error(exception, StackTrace.current);
        }
      },
    );
  }
}
