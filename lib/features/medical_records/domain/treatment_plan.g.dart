// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'treatment_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TreatmentPlan _$TreatmentPlanFromJson(Map<String, dynamic> json) =>
    _TreatmentPlan(
      id: json['id'] as String,
      programId: json['program_id'] as String,
      createdBy: json['created_by'] as String,
      planName: json['plan_name'] as String? ?? 'Plan 1',
      isActive: json['is_active'] as bool? ?? true,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      modalities:
          (json['plan_modalities'] as List<dynamic>?)
              ?.map((e) => PlanModality.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$TreatmentPlanToJson(_TreatmentPlan instance) =>
    <String, dynamic>{
      'id': instance.id,
      'program_id': instance.programId,
      'created_by': instance.createdBy,
      'plan_name': instance.planName,
      'is_active': instance.isActive,
      'notes': instance.notes,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'plan_modalities': instance.modalities,
    };
