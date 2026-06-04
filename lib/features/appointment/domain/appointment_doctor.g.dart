// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment_doctor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppointmentDoctor _$AppointmentDoctorFromJson(Map<String, dynamic> json) =>
    _AppointmentDoctor(
      id: json['id'] as String,
      appointmentId: json['appointment_id'] as String,
      doctorId: json['doctor_id'] as String,
      isReplacement: json['is_replacement'] as bool? ?? false,
      replacedDoctorId: json['replaced_doctor_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      addedBy: json['added_by'] as String?,
      addedAt: DateTime.parse(json['added_at'] as String),
    );

Map<String, dynamic> _$AppointmentDoctorToJson(_AppointmentDoctor instance) =>
    <String, dynamic>{
      'id': instance.id,
      'appointment_id': instance.appointmentId,
      'doctor_id': instance.doctorId,
      'is_replacement': instance.isReplacement,
      'replaced_doctor_id': instance.replacedDoctorId,
      'is_active': instance.isActive,
      'added_by': instance.addedBy,
      'added_at': instance.addedAt.toIso8601String(),
    };
