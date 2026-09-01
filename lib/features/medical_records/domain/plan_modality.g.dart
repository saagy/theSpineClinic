// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_modality.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlanModality _$PlanModalityFromJson(Map<String, dynamic> json) =>
    _PlanModality(
      id: json['id'] as String,
      treatmentPlanId: json['treatment_plan_id'] as String,
      modalityType: $enumDecode(_$ModalityTypeEnumMap, json['modality_type']),
      notes: json['notes'] as String?,
      regions:
          (json['modality_regions'] as List<dynamic>?)
              ?.map((e) => ModalityRegion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$PlanModalityToJson(_PlanModality instance) =>
    <String, dynamic>{
      'id': instance.id,
      'treatment_plan_id': instance.treatmentPlanId,
      'modality_type': _$ModalityTypeEnumMap[instance.modalityType]!,
      'notes': instance.notes,
      'modality_regions': instance.regions,
    };

const _$ModalityTypeEnumMap = {
  ModalityType.musclePain: 'muscle_pain',
  ModalityType.massBuilt: 'mass_built',
  ModalityType.tecar: 'tecar',
  ModalityType.tecarFocal: 'tecar_focal',
  ModalityType.neurodynamicNonWb: 'neurodynamic_non_wb',
  ModalityType.neurodynamicWb: 'neurodynamic_wb',
  ModalityType.release: 'release',
  ModalityType.met: 'met',
  ModalityType.mobilization: 'mobilization',
  ModalityType.mulligan: 'mulligan',
  ModalityType.exercise: 'exercise',
};
