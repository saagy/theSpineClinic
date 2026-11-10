// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'patient.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Patient {

 String get id;@JsonKey(name: 'full_name') String get fullName;@JsonKey(name: 'phone_number') String get phoneNumber; ClinicLocation get clinic;@JsonKey(name: 'file_number') int? get fileNumber;@JsonKey(name: 'personal_details') PatientPersonalDetails get personalDetails;@JsonKey(name: 'session_balance') int get sessionBalance;@JsonKey(name: 'traction_balance') int get tractionBalance;@JsonKey(name: 'created_by') String? get createdBy;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'next_visit_date') DateTime? get nextVisitDate;@JsonKey(includeFromJson: false, includeToJson: false) DateTime? get lastAppointmentDate;
/// Create a copy of Patient
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PatientCopyWith<Patient> get copyWith => _$PatientCopyWithImpl<Patient>(this as Patient, _$identity);

  /// Serializes this Patient to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Patient&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.clinic, clinic) || other.clinic == clinic)&&(identical(other.fileNumber, fileNumber) || other.fileNumber == fileNumber)&&(identical(other.personalDetails, personalDetails) || other.personalDetails == personalDetails)&&(identical(other.sessionBalance, sessionBalance) || other.sessionBalance == sessionBalance)&&(identical(other.tractionBalance, tractionBalance) || other.tractionBalance == tractionBalance)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.nextVisitDate, nextVisitDate) || other.nextVisitDate == nextVisitDate)&&(identical(other.lastAppointmentDate, lastAppointmentDate) || other.lastAppointmentDate == lastAppointmentDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fullName,phoneNumber,clinic,fileNumber,personalDetails,sessionBalance,tractionBalance,createdBy,createdAt,nextVisitDate,lastAppointmentDate);

@override
String toString() {
  return 'Patient(id: $id, fullName: $fullName, phoneNumber: $phoneNumber, clinic: $clinic, fileNumber: $fileNumber, personalDetails: $personalDetails, sessionBalance: $sessionBalance, tractionBalance: $tractionBalance, createdBy: $createdBy, createdAt: $createdAt, nextVisitDate: $nextVisitDate, lastAppointmentDate: $lastAppointmentDate)';
}


}

/// @nodoc
abstract mixin class $PatientCopyWith<$Res>  {
  factory $PatientCopyWith(Patient value, $Res Function(Patient) _then) = _$PatientCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'full_name') String fullName,@JsonKey(name: 'phone_number') String phoneNumber, ClinicLocation clinic,@JsonKey(name: 'file_number') int? fileNumber,@JsonKey(name: 'personal_details') PatientPersonalDetails personalDetails,@JsonKey(name: 'session_balance') int sessionBalance,@JsonKey(name: 'traction_balance') int tractionBalance,@JsonKey(name: 'created_by') String? createdBy,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'next_visit_date') DateTime? nextVisitDate,@JsonKey(includeFromJson: false, includeToJson: false) DateTime? lastAppointmentDate
});


$PatientPersonalDetailsCopyWith<$Res> get personalDetails;

}
/// @nodoc
class _$PatientCopyWithImpl<$Res>
    implements $PatientCopyWith<$Res> {
  _$PatientCopyWithImpl(this._self, this._then);

  final Patient _self;
  final $Res Function(Patient) _then;

/// Create a copy of Patient
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fullName = null,Object? phoneNumber = null,Object? clinic = null,Object? fileNumber = freezed,Object? personalDetails = null,Object? sessionBalance = null,Object? tractionBalance = null,Object? createdBy = freezed,Object? createdAt = null,Object? nextVisitDate = freezed,Object? lastAppointmentDate = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,clinic: null == clinic ? _self.clinic : clinic // ignore: cast_nullable_to_non_nullable
as ClinicLocation,fileNumber: freezed == fileNumber ? _self.fileNumber : fileNumber // ignore: cast_nullable_to_non_nullable
as int?,personalDetails: null == personalDetails ? _self.personalDetails : personalDetails // ignore: cast_nullable_to_non_nullable
as PatientPersonalDetails,sessionBalance: null == sessionBalance ? _self.sessionBalance : sessionBalance // ignore: cast_nullable_to_non_nullable
as int,tractionBalance: null == tractionBalance ? _self.tractionBalance : tractionBalance // ignore: cast_nullable_to_non_nullable
as int,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,nextVisitDate: freezed == nextVisitDate ? _self.nextVisitDate : nextVisitDate // ignore: cast_nullable_to_non_nullable
as DateTime?,lastAppointmentDate: freezed == lastAppointmentDate ? _self.lastAppointmentDate : lastAppointmentDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of Patient
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PatientPersonalDetailsCopyWith<$Res> get personalDetails {

  return $PatientPersonalDetailsCopyWith<$Res>(_self.personalDetails, (value) {
    return _then(_self.copyWith(personalDetails: value));
  });
}
}


/// Adds pattern-matching-related methods to [Patient].
extension PatientPatterns on Patient {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Patient value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Patient() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Patient value)  $default,){
final _that = this;
switch (_that) {
case _Patient():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Patient value)?  $default,){
final _that = this;
switch (_that) {
case _Patient() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'full_name')  String fullName, @JsonKey(name: 'phone_number')  String phoneNumber,  ClinicLocation clinic, @JsonKey(name: 'file_number')  int? fileNumber, @JsonKey(name: 'personal_details')  PatientPersonalDetails personalDetails, @JsonKey(name: 'session_balance')  int sessionBalance, @JsonKey(name: 'traction_balance')  int tractionBalance, @JsonKey(name: 'created_by')  String? createdBy, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'next_visit_date')  DateTime? nextVisitDate, @JsonKey(includeFromJson: false, includeToJson: false)  DateTime? lastAppointmentDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Patient() when $default != null:
return $default(_that.id,_that.fullName,_that.phoneNumber,_that.clinic,_that.fileNumber,_that.personalDetails,_that.sessionBalance,_that.tractionBalance,_that.createdBy,_that.createdAt,_that.nextVisitDate,_that.lastAppointmentDate);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'full_name')  String fullName, @JsonKey(name: 'phone_number')  String phoneNumber,  ClinicLocation clinic, @JsonKey(name: 'file_number')  int? fileNumber, @JsonKey(name: 'personal_details')  PatientPersonalDetails personalDetails, @JsonKey(name: 'session_balance')  int sessionBalance, @JsonKey(name: 'traction_balance')  int tractionBalance, @JsonKey(name: 'created_by')  String? createdBy, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'next_visit_date')  DateTime? nextVisitDate, @JsonKey(includeFromJson: false, includeToJson: false)  DateTime? lastAppointmentDate)  $default,) {final _that = this;
switch (_that) {
case _Patient():
return $default(_that.id,_that.fullName,_that.phoneNumber,_that.clinic,_that.fileNumber,_that.personalDetails,_that.sessionBalance,_that.tractionBalance,_that.createdBy,_that.createdAt,_that.nextVisitDate,_that.lastAppointmentDate);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'full_name')  String fullName, @JsonKey(name: 'phone_number')  String phoneNumber,  ClinicLocation clinic, @JsonKey(name: 'file_number')  int? fileNumber, @JsonKey(name: 'personal_details')  PatientPersonalDetails personalDetails, @JsonKey(name: 'session_balance')  int sessionBalance, @JsonKey(name: 'traction_balance')  int tractionBalance, @JsonKey(name: 'created_by')  String? createdBy, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'next_visit_date')  DateTime? nextVisitDate, @JsonKey(includeFromJson: false, includeToJson: false)  DateTime? lastAppointmentDate)?  $default,) {final _that = this;
switch (_that) {
case _Patient() when $default != null:
return $default(_that.id,_that.fullName,_that.phoneNumber,_that.clinic,_that.fileNumber,_that.personalDetails,_that.sessionBalance,_that.tractionBalance,_that.createdBy,_that.createdAt,_that.nextVisitDate,_that.lastAppointmentDate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Patient implements Patient {
  const _Patient({required this.id, @JsonKey(name: 'full_name') required this.fullName, @JsonKey(name: 'phone_number') required this.phoneNumber, required this.clinic, @JsonKey(name: 'file_number') this.fileNumber, @JsonKey(name: 'personal_details') this.personalDetails = const PatientPersonalDetails(), @JsonKey(name: 'session_balance') this.sessionBalance = 0, @JsonKey(name: 'traction_balance') this.tractionBalance = 0, @JsonKey(name: 'created_by') this.createdBy, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'next_visit_date') this.nextVisitDate, @JsonKey(includeFromJson: false, includeToJson: false) this.lastAppointmentDate});
  factory _Patient.fromJson(Map<String, dynamic> json) => _$PatientFromJson(json);

@override final  String id;
@override@JsonKey(name: 'full_name') final  String fullName;
@override@JsonKey(name: 'phone_number') final  String phoneNumber;
@override final  ClinicLocation clinic;
@override@JsonKey(name: 'file_number') final  int? fileNumber;
@override@JsonKey(name: 'personal_details') final  PatientPersonalDetails personalDetails;
@override@JsonKey(name: 'session_balance') final  int sessionBalance;
@override@JsonKey(name: 'traction_balance') final  int tractionBalance;
@override@JsonKey(name: 'created_by') final  String? createdBy;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'next_visit_date') final  DateTime? nextVisitDate;
@override@JsonKey(includeFromJson: false, includeToJson: false) final  DateTime? lastAppointmentDate;

/// Create a copy of Patient
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PatientCopyWith<_Patient> get copyWith => __$PatientCopyWithImpl<_Patient>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PatientToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Patient&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.clinic, clinic) || other.clinic == clinic)&&(identical(other.fileNumber, fileNumber) || other.fileNumber == fileNumber)&&(identical(other.personalDetails, personalDetails) || other.personalDetails == personalDetails)&&(identical(other.sessionBalance, sessionBalance) || other.sessionBalance == sessionBalance)&&(identical(other.tractionBalance, tractionBalance) || other.tractionBalance == tractionBalance)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.nextVisitDate, nextVisitDate) || other.nextVisitDate == nextVisitDate)&&(identical(other.lastAppointmentDate, lastAppointmentDate) || other.lastAppointmentDate == lastAppointmentDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fullName,phoneNumber,clinic,fileNumber,personalDetails,sessionBalance,tractionBalance,createdBy,createdAt,nextVisitDate,lastAppointmentDate);

@override
String toString() {
  return 'Patient(id: $id, fullName: $fullName, phoneNumber: $phoneNumber, clinic: $clinic, fileNumber: $fileNumber, personalDetails: $personalDetails, sessionBalance: $sessionBalance, tractionBalance: $tractionBalance, createdBy: $createdBy, createdAt: $createdAt, nextVisitDate: $nextVisitDate, lastAppointmentDate: $lastAppointmentDate)';
}


}

/// @nodoc
abstract mixin class _$PatientCopyWith<$Res> implements $PatientCopyWith<$Res> {
  factory _$PatientCopyWith(_Patient value, $Res Function(_Patient) _then) = __$PatientCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'full_name') String fullName,@JsonKey(name: 'phone_number') String phoneNumber, ClinicLocation clinic,@JsonKey(name: 'file_number') int? fileNumber,@JsonKey(name: 'personal_details') PatientPersonalDetails personalDetails,@JsonKey(name: 'session_balance') int sessionBalance,@JsonKey(name: 'traction_balance') int tractionBalance,@JsonKey(name: 'created_by') String? createdBy,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'next_visit_date') DateTime? nextVisitDate,@JsonKey(includeFromJson: false, includeToJson: false) DateTime? lastAppointmentDate
});


@override $PatientPersonalDetailsCopyWith<$Res> get personalDetails;

}
/// @nodoc
class __$PatientCopyWithImpl<$Res>
    implements _$PatientCopyWith<$Res> {
  __$PatientCopyWithImpl(this._self, this._then);

  final _Patient _self;
  final $Res Function(_Patient) _then;

/// Create a copy of Patient
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fullName = null,Object? phoneNumber = null,Object? clinic = null,Object? fileNumber = freezed,Object? personalDetails = null,Object? sessionBalance = null,Object? tractionBalance = null,Object? createdBy = freezed,Object? createdAt = null,Object? nextVisitDate = freezed,Object? lastAppointmentDate = freezed,}) {
  return _then(_Patient(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,clinic: null == clinic ? _self.clinic : clinic // ignore: cast_nullable_to_non_nullable
as ClinicLocation,fileNumber: freezed == fileNumber ? _self.fileNumber : fileNumber // ignore: cast_nullable_to_non_nullable
as int?,personalDetails: null == personalDetails ? _self.personalDetails : personalDetails // ignore: cast_nullable_to_non_nullable
as PatientPersonalDetails,sessionBalance: null == sessionBalance ? _self.sessionBalance : sessionBalance // ignore: cast_nullable_to_non_nullable
as int,tractionBalance: null == tractionBalance ? _self.tractionBalance : tractionBalance // ignore: cast_nullable_to_non_nullable
as int,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,nextVisitDate: freezed == nextVisitDate ? _self.nextVisitDate : nextVisitDate // ignore: cast_nullable_to_non_nullable
as DateTime?,lastAppointmentDate: freezed == lastAppointmentDate ? _self.lastAppointmentDate : lastAppointmentDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of Patient
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PatientPersonalDetailsCopyWith<$Res> get personalDetails {

  return $PatientPersonalDetailsCopyWith<$Res>(_self.personalDetails, (value) {
    return _then(_self.copyWith(personalDetails: value));
  });
}
}


/// @nodoc
mixin _$PatientPersonalDetails {

 String? get address;@JsonKey(name: 'date_of_birth', toJson: _dateOnly) DateTime? get dateOfBirth; String? get nationality; PatientGender? get gender;@JsonKey(name: 'secondary_phone') String? get secondaryPhone;@JsonKey(name: 'insurance_company') String? get insuranceCompany;@JsonKey(name: 'insurance_member_number') String? get insuranceMemberNumber;@JsonKey(name: 'insurance_expiry', toJson: _dateOnly) DateTime? get insuranceExpiry;@JsonKey(name: 'referral_source') String? get referralSource;
/// Create a copy of PatientPersonalDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PatientPersonalDetailsCopyWith<PatientPersonalDetails> get copyWith => _$PatientPersonalDetailsCopyWithImpl<PatientPersonalDetails>(this as PatientPersonalDetails, _$identity);

  /// Serializes this PatientPersonalDetails to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PatientPersonalDetails&&(identical(other.address, address) || other.address == address)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.nationality, nationality) || other.nationality == nationality)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.secondaryPhone, secondaryPhone) || other.secondaryPhone == secondaryPhone)&&(identical(other.insuranceCompany, insuranceCompany) || other.insuranceCompany == insuranceCompany)&&(identical(other.insuranceMemberNumber, insuranceMemberNumber) || other.insuranceMemberNumber == insuranceMemberNumber)&&(identical(other.insuranceExpiry, insuranceExpiry) || other.insuranceExpiry == insuranceExpiry)&&(identical(other.referralSource, referralSource) || other.referralSource == referralSource));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,address,dateOfBirth,nationality,gender,secondaryPhone,insuranceCompany,insuranceMemberNumber,insuranceExpiry,referralSource);

@override
String toString() {
  return 'PatientPersonalDetails(address: $address, dateOfBirth: $dateOfBirth, nationality: $nationality, gender: $gender, secondaryPhone: $secondaryPhone, insuranceCompany: $insuranceCompany, insuranceMemberNumber: $insuranceMemberNumber, insuranceExpiry: $insuranceExpiry, referralSource: $referralSource)';
}


}

/// @nodoc
abstract mixin class $PatientPersonalDetailsCopyWith<$Res>  {
  factory $PatientPersonalDetailsCopyWith(PatientPersonalDetails value, $Res Function(PatientPersonalDetails) _then) = _$PatientPersonalDetailsCopyWithImpl;
@useResult
$Res call({
 String? address,@JsonKey(name: 'date_of_birth', toJson: _dateOnly) DateTime? dateOfBirth, String? nationality, PatientGender? gender,@JsonKey(name: 'secondary_phone') String? secondaryPhone,@JsonKey(name: 'insurance_company') String? insuranceCompany,@JsonKey(name: 'insurance_member_number') String? insuranceMemberNumber,@JsonKey(name: 'insurance_expiry', toJson: _dateOnly) DateTime? insuranceExpiry,@JsonKey(name: 'referral_source') String? referralSource
});




}
/// @nodoc
class _$PatientPersonalDetailsCopyWithImpl<$Res>
    implements $PatientPersonalDetailsCopyWith<$Res> {
  _$PatientPersonalDetailsCopyWithImpl(this._self, this._then);

  final PatientPersonalDetails _self;
  final $Res Function(PatientPersonalDetails) _then;

/// Create a copy of PatientPersonalDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? address = freezed,Object? dateOfBirth = freezed,Object? nationality = freezed,Object? gender = freezed,Object? secondaryPhone = freezed,Object? insuranceCompany = freezed,Object? insuranceMemberNumber = freezed,Object? insuranceExpiry = freezed,Object? referralSource = freezed,}) {
  return _then(_self.copyWith(
address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as DateTime?,nationality: freezed == nationality ? _self.nationality : nationality // ignore: cast_nullable_to_non_nullable
as String?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as PatientGender?,secondaryPhone: freezed == secondaryPhone ? _self.secondaryPhone : secondaryPhone // ignore: cast_nullable_to_non_nullable
as String?,insuranceCompany: freezed == insuranceCompany ? _self.insuranceCompany : insuranceCompany // ignore: cast_nullable_to_non_nullable
as String?,insuranceMemberNumber: freezed == insuranceMemberNumber ? _self.insuranceMemberNumber : insuranceMemberNumber // ignore: cast_nullable_to_non_nullable
as String?,insuranceExpiry: freezed == insuranceExpiry ? _self.insuranceExpiry : insuranceExpiry // ignore: cast_nullable_to_non_nullable
as DateTime?,referralSource: freezed == referralSource ? _self.referralSource : referralSource // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PatientPersonalDetails].
extension PatientPersonalDetailsPatterns on PatientPersonalDetails {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PatientPersonalDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PatientPersonalDetails() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PatientPersonalDetails value)  $default,){
final _that = this;
switch (_that) {
case _PatientPersonalDetails():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PatientPersonalDetails value)?  $default,){
final _that = this;
switch (_that) {
case _PatientPersonalDetails() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? address, @JsonKey(name: 'date_of_birth', toJson: _dateOnly)  DateTime? dateOfBirth,  String? nationality,  PatientGender? gender, @JsonKey(name: 'secondary_phone')  String? secondaryPhone, @JsonKey(name: 'insurance_company')  String? insuranceCompany, @JsonKey(name: 'insurance_member_number')  String? insuranceMemberNumber, @JsonKey(name: 'insurance_expiry', toJson: _dateOnly)  DateTime? insuranceExpiry, @JsonKey(name: 'referral_source')  String? referralSource)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PatientPersonalDetails() when $default != null:
return $default(_that.address,_that.dateOfBirth,_that.nationality,_that.gender,_that.secondaryPhone,_that.insuranceCompany,_that.insuranceMemberNumber,_that.insuranceExpiry,_that.referralSource);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? address, @JsonKey(name: 'date_of_birth', toJson: _dateOnly)  DateTime? dateOfBirth,  String? nationality,  PatientGender? gender, @JsonKey(name: 'secondary_phone')  String? secondaryPhone, @JsonKey(name: 'insurance_company')  String? insuranceCompany, @JsonKey(name: 'insurance_member_number')  String? insuranceMemberNumber, @JsonKey(name: 'insurance_expiry', toJson: _dateOnly)  DateTime? insuranceExpiry, @JsonKey(name: 'referral_source')  String? referralSource)  $default,) {final _that = this;
switch (_that) {
case _PatientPersonalDetails():
return $default(_that.address,_that.dateOfBirth,_that.nationality,_that.gender,_that.secondaryPhone,_that.insuranceCompany,_that.insuranceMemberNumber,_that.insuranceExpiry,_that.referralSource);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? address, @JsonKey(name: 'date_of_birth', toJson: _dateOnly)  DateTime? dateOfBirth,  String? nationality,  PatientGender? gender, @JsonKey(name: 'secondary_phone')  String? secondaryPhone, @JsonKey(name: 'insurance_company')  String? insuranceCompany, @JsonKey(name: 'insurance_member_number')  String? insuranceMemberNumber, @JsonKey(name: 'insurance_expiry', toJson: _dateOnly)  DateTime? insuranceExpiry, @JsonKey(name: 'referral_source')  String? referralSource)?  $default,) {final _that = this;
switch (_that) {
case _PatientPersonalDetails() when $default != null:
return $default(_that.address,_that.dateOfBirth,_that.nationality,_that.gender,_that.secondaryPhone,_that.insuranceCompany,_that.insuranceMemberNumber,_that.insuranceExpiry,_that.referralSource);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PatientPersonalDetails implements PatientPersonalDetails {
  const _PatientPersonalDetails({this.address, @JsonKey(name: 'date_of_birth', toJson: _dateOnly) this.dateOfBirth, this.nationality, this.gender, @JsonKey(name: 'secondary_phone') this.secondaryPhone, @JsonKey(name: 'insurance_company') this.insuranceCompany, @JsonKey(name: 'insurance_member_number') this.insuranceMemberNumber, @JsonKey(name: 'insurance_expiry', toJson: _dateOnly) this.insuranceExpiry, @JsonKey(name: 'referral_source') this.referralSource});
  factory _PatientPersonalDetails.fromJson(Map<String, dynamic> json) => _$PatientPersonalDetailsFromJson(json);

@override final  String? address;
@override@JsonKey(name: 'date_of_birth', toJson: _dateOnly) final  DateTime? dateOfBirth;
@override final  String? nationality;
@override final  PatientGender? gender;
@override@JsonKey(name: 'secondary_phone') final  String? secondaryPhone;
@override@JsonKey(name: 'insurance_company') final  String? insuranceCompany;
@override@JsonKey(name: 'insurance_member_number') final  String? insuranceMemberNumber;
@override@JsonKey(name: 'insurance_expiry', toJson: _dateOnly) final  DateTime? insuranceExpiry;
@override@JsonKey(name: 'referral_source') final  String? referralSource;

/// Create a copy of PatientPersonalDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PatientPersonalDetailsCopyWith<_PatientPersonalDetails> get copyWith => __$PatientPersonalDetailsCopyWithImpl<_PatientPersonalDetails>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PatientPersonalDetailsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PatientPersonalDetails&&(identical(other.address, address) || other.address == address)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.nationality, nationality) || other.nationality == nationality)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.secondaryPhone, secondaryPhone) || other.secondaryPhone == secondaryPhone)&&(identical(other.insuranceCompany, insuranceCompany) || other.insuranceCompany == insuranceCompany)&&(identical(other.insuranceMemberNumber, insuranceMemberNumber) || other.insuranceMemberNumber == insuranceMemberNumber)&&(identical(other.insuranceExpiry, insuranceExpiry) || other.insuranceExpiry == insuranceExpiry)&&(identical(other.referralSource, referralSource) || other.referralSource == referralSource));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,address,dateOfBirth,nationality,gender,secondaryPhone,insuranceCompany,insuranceMemberNumber,insuranceExpiry,referralSource);

@override
String toString() {
  return 'PatientPersonalDetails(address: $address, dateOfBirth: $dateOfBirth, nationality: $nationality, gender: $gender, secondaryPhone: $secondaryPhone, insuranceCompany: $insuranceCompany, insuranceMemberNumber: $insuranceMemberNumber, insuranceExpiry: $insuranceExpiry, referralSource: $referralSource)';
}


}

/// @nodoc
abstract mixin class _$PatientPersonalDetailsCopyWith<$Res> implements $PatientPersonalDetailsCopyWith<$Res> {
  factory _$PatientPersonalDetailsCopyWith(_PatientPersonalDetails value, $Res Function(_PatientPersonalDetails) _then) = __$PatientPersonalDetailsCopyWithImpl;
@override @useResult
$Res call({
 String? address,@JsonKey(name: 'date_of_birth', toJson: _dateOnly) DateTime? dateOfBirth, String? nationality, PatientGender? gender,@JsonKey(name: 'secondary_phone') String? secondaryPhone,@JsonKey(name: 'insurance_company') String? insuranceCompany,@JsonKey(name: 'insurance_member_number') String? insuranceMemberNumber,@JsonKey(name: 'insurance_expiry', toJson: _dateOnly) DateTime? insuranceExpiry,@JsonKey(name: 'referral_source') String? referralSource
});




}
/// @nodoc
class __$PatientPersonalDetailsCopyWithImpl<$Res>
    implements _$PatientPersonalDetailsCopyWith<$Res> {
  __$PatientPersonalDetailsCopyWithImpl(this._self, this._then);

  final _PatientPersonalDetails _self;
  final $Res Function(_PatientPersonalDetails) _then;

/// Create a copy of PatientPersonalDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? address = freezed,Object? dateOfBirth = freezed,Object? nationality = freezed,Object? gender = freezed,Object? secondaryPhone = freezed,Object? insuranceCompany = freezed,Object? insuranceMemberNumber = freezed,Object? insuranceExpiry = freezed,Object? referralSource = freezed,}) {
  return _then(_PatientPersonalDetails(
address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as DateTime?,nationality: freezed == nationality ? _self.nationality : nationality // ignore: cast_nullable_to_non_nullable
as String?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as PatientGender?,secondaryPhone: freezed == secondaryPhone ? _self.secondaryPhone : secondaryPhone // ignore: cast_nullable_to_non_nullable
as String?,insuranceCompany: freezed == insuranceCompany ? _self.insuranceCompany : insuranceCompany // ignore: cast_nullable_to_non_nullable
as String?,insuranceMemberNumber: freezed == insuranceMemberNumber ? _self.insuranceMemberNumber : insuranceMemberNumber // ignore: cast_nullable_to_non_nullable
as String?,insuranceExpiry: freezed == insuranceExpiry ? _self.insuranceExpiry : insuranceExpiry // ignore: cast_nullable_to_non_nullable
as DateTime?,referralSource: freezed == referralSource ? _self.referralSource : referralSource // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
