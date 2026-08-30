// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'program_condition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProgramCondition _$ProgramConditionFromJson(Map<String, dynamic> json) =>
    _ProgramCondition(
      id: json['id'] as String,
      programId: json['program_id'] as String,
      conditionId: json['condition_id'] as String,
      condition: json['condition_catalog'] == null
          ? null
          : ConditionCatalog.fromJson(
              json['condition_catalog'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$ProgramConditionToJson(_ProgramCondition instance) =>
    <String, dynamic>{
      'id': instance.id,
      'program_id': instance.programId,
      'condition_id': instance.conditionId,
      'condition_catalog': instance.condition,
    };
