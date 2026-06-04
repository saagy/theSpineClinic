// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Patient _$PatientFromJson(Map<String, dynamic> json) => _Patient(
  id: json['id'] as String,
  fullName: json['full_name'] as String,
  phoneNumber: json['phone_number'] as String,
  program: json['program'] as String?,
  clinic: $enumDecode(_$ClinicLocationEnumMap, json['clinic']),
  packageBalance: (json['package_balance'] as num?)?.toInt() ?? 0,
  createdBy: json['created_by'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$PatientToJson(_Patient instance) => <String, dynamic>{
  'id': instance.id,
  'full_name': instance.fullName,
  'phone_number': instance.phoneNumber,
  'program': instance.program,
  'clinic': _$ClinicLocationEnumMap[instance.clinic]!,
  'package_balance': instance.packageBalance,
  'created_by': instance.createdBy,
  'created_at': instance.createdAt.toIso8601String(),
};

const _$ClinicLocationEnumMap = {
  ClinicLocation.tagamoa: 'tagamoa',
  ClinicLocation.masrElgedida: 'masr_elgedida',
};
