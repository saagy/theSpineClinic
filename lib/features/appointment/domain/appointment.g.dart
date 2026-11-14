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
  branch: $enumDecodeNullable(
    _$ClinicLocationEnumMap,
    json['branch'],
    unknownValue: JsonKey.nullForUndefinedEnumValue,
  ),
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
      'branch': _$ClinicLocationEnumMap[instance.branch],
    };

const _$AppointmentTypeEnumMap = {
  AppointmentType.normalPtSession: 'normal_pt_session',
  AppointmentType.spinalTractionSession: 'spinal_traction_session',
  AppointmentType.initialAssessment: 'initial_assessment',
  AppointmentType.reassessment: 'reassessment',
};

const _$AppointmentStatusEnumMap = {
  AppointmentStatus.scheduled: 'scheduled',
  AppointmentStatus.checkedIn: 'checked_in',
  AppointmentStatus.cancelled: 'cancelled',
};

const _$ClinicLocationEnumMap = {
  ClinicLocation.tagamoa: 'tagamoa',
  ClinicLocation.masrElgedida: 'masr_elgedida',
  ClinicLocation.madinaty: 'madinaty',
};
