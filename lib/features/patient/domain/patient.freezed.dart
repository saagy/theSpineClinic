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

 String get id;@JsonKey(name: 'full_name') String get fullName;@JsonKey(name: 'phone_number') String get phoneNumber; String? get program; ClinicLocation get clinic;@JsonKey(name: 'session_balance') int get sessionBalance;@JsonKey(name: 'traction_balance') int get tractionBalance;@JsonKey(name: 'created_by') String? get createdBy;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(includeFromJson: false, includeToJson: false) DateTime? get lastAppointmentDate;
/// Create a copy of Patient
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PatientCopyWith<Patient> get copyWith => _$PatientCopyWithImpl<Patient>(this as Patient, _$identity);

  /// Serializes this Patient to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Patient&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.program, program) || other.program == program)&&(identical(other.clinic, clinic) || other.clinic == clinic)&&(identical(other.sessionBalance, sessionBalance) || other.sessionBalance == sessionBalance)&&(identical(other.tractionBalance, tractionBalance) || other.tractionBalance == tractionBalance)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastAppointmentDate, lastAppointmentDate) || other.lastAppointmentDate == lastAppointmentDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fullName,phoneNumber,program,clinic,sessionBalance,tractionBalance,createdBy,createdAt,lastAppointmentDate);

@override
String toString() {
  return 'Patient(id: $id, fullName: $fullName, phoneNumber: $phoneNumber, program: $program, clinic: $clinic, sessionBalance: $sessionBalance, tractionBalance: $tractionBalance, createdBy: $createdBy, createdAt: $createdAt, lastAppointmentDate: $lastAppointmentDate)';
}


}

/// @nodoc
abstract mixin class $PatientCopyWith<$Res>  {
  factory $PatientCopyWith(Patient value, $Res Function(Patient) _then) = _$PatientCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'full_name') String fullName,@JsonKey(name: 'phone_number') String phoneNumber, String? program, ClinicLocation clinic,@JsonKey(name: 'session_balance') int sessionBalance,@JsonKey(name: 'traction_balance') int tractionBalance,@JsonKey(name: 'created_by') String? createdBy,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(includeFromJson: false, includeToJson: false) DateTime? lastAppointmentDate
});




}
/// @nodoc
class _$PatientCopyWithImpl<$Res>
    implements $PatientCopyWith<$Res> {
  _$PatientCopyWithImpl(this._self, this._then);

  final Patient _self;
  final $Res Function(Patient) _then;

/// Create a copy of Patient
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fullName = null,Object? phoneNumber = null,Object? program = freezed,Object? clinic = null,Object? sessionBalance = null,Object? tractionBalance = null,Object? createdBy = freezed,Object? createdAt = null,Object? lastAppointmentDate = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,program: freezed == program ? _self.program : program // ignore: cast_nullable_to_non_nullable
as String?,clinic: null == clinic ? _self.clinic : clinic // ignore: cast_nullable_to_non_nullable
as ClinicLocation,sessionBalance: null == sessionBalance ? _self.sessionBalance : sessionBalance // ignore: cast_nullable_to_non_nullable
as int,tractionBalance: null == tractionBalance ? _self.tractionBalance : tractionBalance // ignore: cast_nullable_to_non_nullable
as int,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastAppointmentDate: freezed == lastAppointmentDate ? _self.lastAppointmentDate : lastAppointmentDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'full_name')  String fullName, @JsonKey(name: 'phone_number')  String phoneNumber,  String? program,  ClinicLocation clinic, @JsonKey(name: 'session_balance')  int sessionBalance, @JsonKey(name: 'traction_balance')  int tractionBalance, @JsonKey(name: 'created_by')  String? createdBy, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(includeFromJson: false, includeToJson: false)  DateTime? lastAppointmentDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Patient() when $default != null:
return $default(_that.id,_that.fullName,_that.phoneNumber,_that.program,_that.clinic,_that.sessionBalance,_that.tractionBalance,_that.createdBy,_that.createdAt,_that.lastAppointmentDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'full_name')  String fullName, @JsonKey(name: 'phone_number')  String phoneNumber,  String? program,  ClinicLocation clinic, @JsonKey(name: 'session_balance')  int sessionBalance, @JsonKey(name: 'traction_balance')  int tractionBalance, @JsonKey(name: 'created_by')  String? createdBy, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(includeFromJson: false, includeToJson: false)  DateTime? lastAppointmentDate)  $default,) {final _that = this;
switch (_that) {
case _Patient():
return $default(_that.id,_that.fullName,_that.phoneNumber,_that.program,_that.clinic,_that.sessionBalance,_that.tractionBalance,_that.createdBy,_that.createdAt,_that.lastAppointmentDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'full_name')  String fullName, @JsonKey(name: 'phone_number')  String phoneNumber,  String? program,  ClinicLocation clinic, @JsonKey(name: 'session_balance')  int sessionBalance, @JsonKey(name: 'traction_balance')  int tractionBalance, @JsonKey(name: 'created_by')  String? createdBy, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(includeFromJson: false, includeToJson: false)  DateTime? lastAppointmentDate)?  $default,) {final _that = this;
switch (_that) {
case _Patient() when $default != null:
return $default(_that.id,_that.fullName,_that.phoneNumber,_that.program,_that.clinic,_that.sessionBalance,_that.tractionBalance,_that.createdBy,_that.createdAt,_that.lastAppointmentDate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Patient implements Patient {
  const _Patient({required this.id, @JsonKey(name: 'full_name') required this.fullName, @JsonKey(name: 'phone_number') required this.phoneNumber, this.program, required this.clinic, @JsonKey(name: 'session_balance') this.sessionBalance = 0, @JsonKey(name: 'traction_balance') this.tractionBalance = 0, @JsonKey(name: 'created_by') this.createdBy, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(includeFromJson: false, includeToJson: false) this.lastAppointmentDate});
  factory _Patient.fromJson(Map<String, dynamic> json) => _$PatientFromJson(json);

@override final  String id;
@override@JsonKey(name: 'full_name') final  String fullName;
@override@JsonKey(name: 'phone_number') final  String phoneNumber;
@override final  String? program;
@override final  ClinicLocation clinic;
@override@JsonKey(name: 'session_balance') final  int sessionBalance;
@override@JsonKey(name: 'traction_balance') final  int tractionBalance;
@override@JsonKey(name: 'created_by') final  String? createdBy;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Patient&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.program, program) || other.program == program)&&(identical(other.clinic, clinic) || other.clinic == clinic)&&(identical(other.sessionBalance, sessionBalance) || other.sessionBalance == sessionBalance)&&(identical(other.tractionBalance, tractionBalance) || other.tractionBalance == tractionBalance)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastAppointmentDate, lastAppointmentDate) || other.lastAppointmentDate == lastAppointmentDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fullName,phoneNumber,program,clinic,sessionBalance,tractionBalance,createdBy,createdAt,lastAppointmentDate);

@override
String toString() {
  return 'Patient(id: $id, fullName: $fullName, phoneNumber: $phoneNumber, program: $program, clinic: $clinic, sessionBalance: $sessionBalance, tractionBalance: $tractionBalance, createdBy: $createdBy, createdAt: $createdAt, lastAppointmentDate: $lastAppointmentDate)';
}


}

/// @nodoc
abstract mixin class _$PatientCopyWith<$Res> implements $PatientCopyWith<$Res> {
  factory _$PatientCopyWith(_Patient value, $Res Function(_Patient) _then) = __$PatientCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'full_name') String fullName,@JsonKey(name: 'phone_number') String phoneNumber, String? program, ClinicLocation clinic,@JsonKey(name: 'session_balance') int sessionBalance,@JsonKey(name: 'traction_balance') int tractionBalance,@JsonKey(name: 'created_by') String? createdBy,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(includeFromJson: false, includeToJson: false) DateTime? lastAppointmentDate
});




}
/// @nodoc
class __$PatientCopyWithImpl<$Res>
    implements _$PatientCopyWith<$Res> {
  __$PatientCopyWithImpl(this._self, this._then);

  final _Patient _self;
  final $Res Function(_Patient) _then;

/// Create a copy of Patient
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fullName = null,Object? phoneNumber = null,Object? program = freezed,Object? clinic = null,Object? sessionBalance = null,Object? tractionBalance = null,Object? createdBy = freezed,Object? createdAt = null,Object? lastAppointmentDate = freezed,}) {
  return _then(_Patient(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,program: freezed == program ? _self.program : program // ignore: cast_nullable_to_non_nullable
as String?,clinic: null == clinic ? _self.clinic : clinic // ignore: cast_nullable_to_non_nullable
as ClinicLocation,sessionBalance: null == sessionBalance ? _self.sessionBalance : sessionBalance // ignore: cast_nullable_to_non_nullable
as int,tractionBalance: null == tractionBalance ? _self.tractionBalance : tractionBalance // ignore: cast_nullable_to_non_nullable
as int,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastAppointmentDate: freezed == lastAppointmentDate ? _self.lastAppointmentDate : lastAppointmentDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
