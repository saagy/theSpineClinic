// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Appointment _$AppointmentFromJson(Map<String, dynamic> json) => _Appointment(
  id: json['id'] as String,
  patientId: json['patient_id'] as String,
  type: $enumDecode(_$AppointmentTypeEnumMap, json['type']),
  scheduledAt: DateTime.parse(json['scheduled_at'] as String),
  status:
      $enumDecodeNullable(_$AppointmentStatusEnumMap, json['status']) ??
      AppointmentStatus.scheduled,
  usePackage: json['use_package'] as bool? ?? true,
  createdBy: json['created_by'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$AppointmentToJson(_Appointment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'patient_id': instance.patientId,
      'type': _$AppointmentTypeEnumMap[instance.type]!,
      'scheduled_at': instance.scheduledAt.toIso8601String(),
      'status': _$AppointmentStatusEnumMap[instance.status]!,
      'use_package': instance.usePackage,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$AppointmentTypeEnumMap = {
  AppointmentType.session: 'session',
  AppointmentType.gehazShadFakarat: 'gehaz_shad_fakarat',
  AppointmentType.checkUp: 'check_up',
};

const _$AppointmentStatusEnumMap = {
  AppointmentStatus.scheduled: 'scheduled',
  AppointmentStatus.checkedIn: 'checked_in',
  AppointmentStatus.completed: 'completed',
  AppointmentStatus.cancelled: 'cancelled',
  AppointmentStatus.noShow: 'no_show',
};
