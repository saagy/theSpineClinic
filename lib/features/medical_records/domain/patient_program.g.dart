// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_program.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PatientProgram _$PatientProgramFromJson(Map<String, dynamic> json) =>
    _PatientProgram(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      createdBy: json['created_by'] as String,
      status:
          $enumDecodeNullable(_$ProgramStatusEnumMap, json['status']) ??
          ProgramStatus.active,
      examination: json['examination'] as String?,
      imagingNotes: json['imaging_notes'] as String?,
      exaggeratingPositions: json['exaggerating_positions'] as String?,
      relievingPositions: json['relieving_positions'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      conditions:
          (json['program_conditions'] as List<dynamic>?)
              ?.map((e) => ProgramCondition.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      treatmentPlans:
          (json['treatment_plans'] as List<dynamic>?)
              ?.map((e) => TreatmentPlan.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$PatientProgramToJson(_PatientProgram instance) =>
    <String, dynamic>{
      'id': instance.id,
      'patient_id': instance.patientId,
      'created_by': instance.createdBy,
      'status': _$ProgramStatusEnumMap[instance.status]!,
      'examination': instance.examination,
      'imaging_notes': instance.imagingNotes,
      'exaggerating_positions': instance.exaggeratingPositions,
      'relieving_positions': instance.relievingPositions,
      'notes': instance.notes,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'program_conditions': instance.conditions,
      'treatment_plans': instance.treatmentPlans,
    };

const _$ProgramStatusEnumMap = {
  ProgramStatus.active: 'active',
  ProgramStatus.completed: 'completed',
  ProgramStatus.archived: 'archived',
};
