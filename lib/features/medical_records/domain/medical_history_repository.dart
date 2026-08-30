library;

import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_medical_history.dart';

/// Defines medical history data operations.
abstract class MedicalHistoryRepository {
  /// Fetches the medical history for a specific patient.
  /// Returns null if no record exists yet.
  Future<Result<PatientMedicalHistory?>> getMedicalHistory(String patientId);

  /// Creates or updates the medical history for a patient.
  Future<Result<PatientMedicalHistory>> upsertMedicalHistory(
    PatientMedicalHistory history,
  );
}
