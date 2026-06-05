// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clinic_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ClinicSettings _$ClinicSettingsFromJson(Map<String, dynamic> json) =>
    _ClinicSettings(
      id: json['id'] as String,
      packages: (json['packages'] as List<dynamic>)
          .map((e) => ClinicPackage.fromJson(e as Map<String, dynamic>))
          .toList(),
      updatedBy: json['updated_by'] as String?,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$ClinicSettingsToJson(_ClinicSettings instance) =>
    <String, dynamic>{
      'id': instance.id,
      'packages': instance.packages,
      'updated_by': instance.updatedBy,
      'updated_at': instance.updatedAt.toIso8601String(),
    };
