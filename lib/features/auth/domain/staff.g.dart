// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Staff _$StaffFromJson(Map<String, dynamic> json) => _Staff(
  id: json['id'] as String,
  userId: json['user_id'] as String?,
  fullName: json['full_name'] as String,
  email: json['email'] as String,
  phone: json['phone'] as String?,
  role: $enumDecode(_$UserRoleEnumMap, json['role']),
  isActive: json['is_active'] as bool? ?? true,
  canManagePayments: json['can_manage_payments'] as bool? ?? false,
  isSenior: json['is_senior'] as bool? ?? false,
  branch: $enumDecodeNullable(_$ClinicLocationEnumMap, json['branch']),
  deactivatedAt: json['deactivated_at'] == null
      ? null
      : DateTime.parse(json['deactivated_at'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$StaffToJson(_Staff instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'full_name': instance.fullName,
  'email': instance.email,
  'phone': instance.phone,
  'role': _$UserRoleEnumMap[instance.role]!,
  'is_active': instance.isActive,
  'can_manage_payments': instance.canManagePayments,
  'is_senior': instance.isSenior,
  'branch': _$ClinicLocationEnumMap[instance.branch],
  'deactivated_at': instance.deactivatedAt?.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
};

const _$UserRoleEnumMap = {
  UserRole.superAdmin: 'super_admin',
  UserRole.receptionist: 'receptionist',
  UserRole.doctor: 'doctor',
};

const _$ClinicLocationEnumMap = {
  ClinicLocation.tagamoa: 'tagamoa',
  ClinicLocation.masrElgedida: 'masr_elgedida',
};
