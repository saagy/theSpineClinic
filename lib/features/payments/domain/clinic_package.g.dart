// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clinic_package.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ClinicPackage _$ClinicPackageFromJson(Map<String, dynamic> json) =>
    _ClinicPackage(
      name: json['name'] as String,
      sessionCount: (json['session_count'] as num).toInt(),
      price: _priceFromJson(json['price']),
    );

Map<String, dynamic> _$ClinicPackageToJson(_ClinicPackage instance) =>
    <String, dynamic>{
      'name': instance.name,
      'session_count': instance.sessionCount,
      'price': _priceToJson(instance.price),
    };
