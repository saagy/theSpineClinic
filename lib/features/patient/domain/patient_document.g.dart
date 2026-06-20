// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PatientDocument _$PatientDocumentFromJson(Map<String, dynamic> json) =>
    _PatientDocument(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      fileUrl: json['file_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      fileName: json['file_name'] as String,
      uploadedBy: json['uploaded_by'] as String?,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
    );

Map<String, dynamic> _$PatientDocumentToJson(_PatientDocument instance) =>
    <String, dynamic>{
      'id': instance.id,
      'patient_id': instance.patientId,
      'file_url': instance.fileUrl,
      'thumbnail_url': instance.thumbnailUrl,
      'file_name': instance.fileName,
      'uploaded_by': instance.uploadedBy,
      'uploaded_at': instance.uploadedAt.toIso8601String(),
    };
