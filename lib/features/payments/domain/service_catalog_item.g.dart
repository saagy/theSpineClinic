// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_catalog_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ServiceCatalogItem _$ServiceCatalogItemFromJson(Map<String, dynamic> json) =>
    _ServiceCatalogItem(
      id: json['id'] as String,
      name: json['name'] as String,
      type: _typeFromJson(json['service_type'] as String),
      sessionsPerUnit: (json['sessions_per_unit'] as num).toInt(),
      priceMinor: (json['price_minor'] as num).toInt(),
      creditsDoctors: json['attributes_doctors'] as bool,
      active: json['active'] as bool,
      version: (json['version'] as num).toInt(),
    );

Map<String, dynamic> _$ServiceCatalogItemToJson(_ServiceCatalogItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'service_type': _typeToJson(instance.type),
      'sessions_per_unit': instance.sessionsPerUnit,
      'price_minor': instance.priceMinor,
      'attributes_doctors': instance.creditsDoctors,
      'active': instance.active,
      'version': instance.version,
    };
