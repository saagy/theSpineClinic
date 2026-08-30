// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_medical_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PatientMedicalHistory _$PatientMedicalHistoryFromJson(
  Map<String, dynamic> json,
) => _PatientMedicalHistory(
  id: json['id'] as String,
  patientId: json['patient_id'] as String,
  hasDiabetes: json['has_diabetes'] as bool? ?? false,
  hba1cValue: json['hba1c_value'] as String?,
  hasHypertension: json['has_hypertension'] as bool? ?? false,
  hasHyperlipidemia: json['has_hyperlipidemia'] as bool? ?? false,
  hasRheumatology: json['has_rheumatology'] as bool? ?? false,
  rheumatologyDetails: json['rheumatology_details'] as String?,
  additionalNotes: json['additional_notes'] as String?,
  updatedBy: json['updated_by'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$PatientMedicalHistoryToJson(
  _PatientMedicalHistory instance,
) => <String, dynamic>{
  'id': instance.id,
  'patient_id': instance.patientId,
  'has_diabetes': instance.hasDiabetes,
  'hba1c_value': instance.hba1cValue,
  'has_hypertension': instance.hasHypertension,
  'has_hyperlipidemia': instance.hasHyperlipidemia,
  'has_rheumatology': instance.hasRheumatology,
  'rheumatology_details': instance.rheumatologyDetails,
  'additional_notes': instance.additionalNotes,
  'updated_by': instance.updatedBy,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
