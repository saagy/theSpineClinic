library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'patient_medical_history.freezed.dart';
part 'patient_medical_history.g.dart';

/// Represents structured medical history for a patient.
@freezed
abstract class PatientMedicalHistory with _$PatientMedicalHistory {
  const PatientMedicalHistory._();

  const factory PatientMedicalHistory({
    required String id,
    @JsonKey(name: 'patient_id') required String patientId,
    @JsonKey(name: 'has_diabetes') @Default(false) bool hasDiabetes,
    @JsonKey(name: 'hba1c_value') String? hba1cValue,
    @JsonKey(name: 'has_hypertension') @Default(false) bool hasHypertension,
    @JsonKey(name: 'has_hyperlipidemia') @Default(false) bool hasHyperlipidemia,
    @JsonKey(name: 'has_rheumatology') @Default(false) bool hasRheumatology,
    @JsonKey(name: 'rheumatology_details') String? rheumatologyDetails,
    @JsonKey(name: 'additional_notes') String? additionalNotes,
    @JsonKey(name: 'updated_by') String? updatedBy,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _PatientMedicalHistory;

  factory PatientMedicalHistory.fromJson(Map<String, dynamic> json) =>
      _$PatientMedicalHistoryFromJson(json);

  /// Whether any condition or note has been recorded.
  bool get hasAnyCondition =>
      hasDiabetes ||
      hasHypertension ||
      hasHyperlipidemia ||
      hasRheumatology ||
      (additionalNotes != null && additionalNotes!.trim().isNotEmpty);
}
