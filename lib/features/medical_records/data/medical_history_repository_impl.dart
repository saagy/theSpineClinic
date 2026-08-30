library;

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/medical_records/domain/medical_history_repository.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_medical_history.dart';

/// Supabase-backed implementation of [MedicalHistoryRepository].
class MedicalHistoryRepositoryImpl implements MedicalHistoryRepository {
  MedicalHistoryRepositoryImpl({required SupabaseService supabaseService})
      : _service = supabaseService;

  final SupabaseService _service;

  @override
  Future<Result<PatientMedicalHistory?>> getMedicalHistory(
    String patientId,
  ) async {
    try {
      final data = await _service.guardQuery(
        () => _service
            .from('patient_medical_history')
            .select()
            .eq('patient_id', patientId)
            .maybeSingle(),
      );
      if (data == null) {
        return const Result.success(null);
      }
      return Result.success(PatientMedicalHistory.fromJson(data));
    } on Exception catch (error) {
      return Result.failure(
        error is AppException
            ? error
            : AppException.fromSupabaseException(error),
      );
    }
  }

  @override
  Future<Result<PatientMedicalHistory>> upsertMedicalHistory(
    PatientMedicalHistory history,
  ) async {
    try {
      final payload = <String, dynamic>{
        'patient_id': history.patientId,
        'has_diabetes': history.hasDiabetes,
        'hba1c_value': history.hasDiabetes ? history.hba1cValue : null,
        'has_hypertension': history.hasHypertension,
        'has_hyperlipidemia': history.hasHyperlipidemia,
        'has_rheumatology': history.hasRheumatology,
        'rheumatology_details':
            history.hasRheumatology ? history.rheumatologyDetails : null,
        'additional_notes': history.additionalNotes,
        'updated_by': history.updatedBy,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      final data = await _service.guardQuery(
        () => _service
            .from('patient_medical_history')
            .upsert(payload, onConflict: 'patient_id')
            .select()
            .single(),
      );
      return Result.success(PatientMedicalHistory.fromJson(data));
    } on Exception catch (error) {
      return Result.failure(
        error is AppException
            ? error
            : AppException.fromSupabaseException(error),
      );
    }
  }
}
