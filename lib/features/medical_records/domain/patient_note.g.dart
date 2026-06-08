// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_note.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PatientNote _$PatientNoteFromJson(Map<String, dynamic> json) => _PatientNote(
  id: json['id'] as String,
  patientId: json['patient_id'] as String,
  appointmentId: json['appointment_id'] as String?,
  createdBy: json['created_by'] as String,
  noteText: json['note_text'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$PatientNoteToJson(_PatientNote instance) =>
    <String, dynamic>{
      'id': instance.id,
      'patient_id': instance.patientId,
      'appointment_id': instance.appointmentId,
      'created_by': instance.createdBy,
      'note_text': instance.noteText,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
