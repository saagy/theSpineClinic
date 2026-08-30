// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'modality_region.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ModalityRegion _$ModalityRegionFromJson(Map<String, dynamic> json) =>
    _ModalityRegion(
      id: json['id'] as String,
      planModalityId: json['plan_modality_id'] as String,
      targetRegion: json['target_region'] as String,
      laterality: $enumDecodeNullable(_$LateralityEnumMap, json['laterality']),
      timeMinutes: (json['time_minutes'] as num?)?.toInt() ?? 15,
    );

Map<String, dynamic> _$ModalityRegionToJson(_ModalityRegion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'plan_modality_id': instance.planModalityId,
      'target_region': instance.targetRegion,
      'laterality': _$LateralityEnumMap[instance.laterality],
      'time_minutes': instance.timeMinutes,
    };

const _$LateralityEnumMap = {
  Laterality.right: 'right',
  Laterality.left: 'left',
  Laterality.both: 'both',
};
