// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Patient _$PatientFromJson(Map<String, dynamic> json) => _Patient(
  id: json['id'] as String,
  fullName: json['full_name'] as String,
  phoneNumber: json['phone_number'] as String,
  clinic: $enumDecode(_$ClinicLocationEnumMap, json['clinic']),
  fileNumber: (json['file_number'] as num?)?.toInt(),
  personalDetails: json['personal_details'] == null
      ? const PatientPersonalDetails()
      : PatientPersonalDetails.fromJson(
          json['personal_details'] as Map<String, dynamic>,
        ),
  sessionBalance: (json['session_balance'] as num?)?.toInt() ?? 0,
  tractionBalance: (json['traction_balance'] as num?)?.toInt() ?? 0,
  createdBy: json['created_by'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  nextVisitDate: json['next_visit_date'] == null
      ? null
      : DateTime.parse(json['next_visit_date'] as String),
);

Map<String, dynamic> _$PatientToJson(_Patient instance) => <String, dynamic>{
  'id': instance.id,
  'full_name': instance.fullName,
  'phone_number': instance.phoneNumber,
  'clinic': _$ClinicLocationEnumMap[instance.clinic]!,
  'file_number': instance.fileNumber,
  'personal_details': instance.personalDetails,
  'session_balance': instance.sessionBalance,
  'traction_balance': instance.tractionBalance,
  'created_by': instance.createdBy,
  'created_at': instance.createdAt.toIso8601String(),
  'next_visit_date': instance.nextVisitDate?.toIso8601String(),
};

const _$ClinicLocationEnumMap = {
  ClinicLocation.tagamoa: 'tagamoa',
  ClinicLocation.masrElgedida: 'masr_elgedida',
};

_PatientPersonalDetails _$PatientPersonalDetailsFromJson(
  Map<String, dynamic> json,
) => _PatientPersonalDetails(
  address: json['address'] as String?,
  dateOfBirth: json['date_of_birth'] == null
      ? null
      : DateTime.parse(json['date_of_birth'] as String),
  nationality: json['nationality'] as String?,
  gender: $enumDecodeNullable(_$PatientGenderEnumMap, json['gender']),
  secondaryPhone: json['secondary_phone'] as String?,
  insuranceCompany: json['insurance_company'] as String?,
  insuranceMemberNumber: json['insurance_member_number'] as String?,
  insuranceExpiry: json['insurance_expiry'] == null
      ? null
      : DateTime.parse(json['insurance_expiry'] as String),
  referralSource: json['referral_source'] as String?,
);

Map<String, dynamic> _$PatientPersonalDetailsToJson(
  _PatientPersonalDetails instance,
) => <String, dynamic>{
  'address': instance.address,
  'date_of_birth': _dateOnly(instance.dateOfBirth),
  'nationality': instance.nationality,
  'gender': _$PatientGenderEnumMap[instance.gender],
  'secondary_phone': instance.secondaryPhone,
  'insurance_company': instance.insuranceCompany,
  'insurance_member_number': instance.insuranceMemberNumber,
  'insurance_expiry': _dateOnly(instance.insuranceExpiry),
  'referral_source': instance.referralSource,
};

const _$PatientGenderEnumMap = {
  PatientGender.female: 'female',
  PatientGender.male: 'male',
};
