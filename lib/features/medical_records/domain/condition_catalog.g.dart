// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'condition_catalog.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ConditionCatalog _$ConditionCatalogFromJson(Map<String, dynamic> json) =>
    _ConditionCatalog(
      id: json['id'] as String,
      region: $enumDecode(_$BodyRegionEnumMap, json['region']),
      conditionName: json['condition_name'] as String,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ConditionCatalogToJson(_ConditionCatalog instance) =>
    <String, dynamic>{
      'id': instance.id,
      'region': _$BodyRegionEnumMap[instance.region]!,
      'condition_name': instance.conditionName,
      'display_order': instance.displayOrder,
      'created_at': instance.createdAt?.toIso8601String(),
    };

const _$BodyRegionEnumMap = {
  BodyRegion.shoulder: 'shoulder',
  BodyRegion.elbow: 'elbow',
  BodyRegion.hand: 'hand',
  BodyRegion.lumbarSpine: 'lumbar_spine',
  BodyRegion.thoracicSpine: 'thoracic_spine',
  BodyRegion.cervicalSpine: 'cervical_spine',
  BodyRegion.hipJoint: 'hip_joint',
  BodyRegion.kneeJoint: 'knee_joint',
  BodyRegion.ankleJoint: 'ankle_joint',
  BodyRegion.foot: 'foot',
};
