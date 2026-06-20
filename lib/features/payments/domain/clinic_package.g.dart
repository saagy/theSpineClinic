// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clinic_package.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ClinicPackage _$ClinicPackageFromJson(Map<String, dynamic> json) =>
    _ClinicPackage(
      name: json['name'] as String,
      kind:
          $enumDecodeNullable(_$PackageKindEnumMap, json['kind']) ??
          PackageKind.session,
      sessionCount: (json['session_count'] as num?)?.toInt() ?? 0,
      tractionsCount: (json['tractions_count'] as num?)?.toInt() ?? 0,
      price: _priceFromJson(json['price']),
    );

Map<String, dynamic> _$ClinicPackageToJson(_ClinicPackage instance) =>
    <String, dynamic>{
      'name': instance.name,
      'kind': _$PackageKindEnumMap[instance.kind]!,
      'session_count': instance.sessionCount,
      'tractions_count': instance.tractionsCount,
      'price': _priceToJson(instance.price),
    };

const _$PackageKindEnumMap = {
  PackageKind.session: 'session',
  PackageKind.traction: 'traction',
  PackageKind.combined: 'combined',
};
