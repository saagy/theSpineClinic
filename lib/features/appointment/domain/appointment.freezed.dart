// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'appointment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Appointment {

/// Primary key (`uuid`).
 String get id;/// FK references `patients(id)`.
@JsonKey(name: 'patient_id') String get patientId;/// Type of the appointment (session or traction device).
 AppointmentType get type;/// Time the appointment is scheduled for.
@JsonKey(name: 'scheduled_at') DateTime get scheduledAt;/// Workflow status of the appointment.
 AppointmentStatus get status;/// Whether this appointment uses/deducts from the patient's package balance.
@JsonKey(name: 'use_package') bool get usePackage;/// FK references `staff(id)` representing the receptionist/admin who booked it.
@JsonKey(name: 'created_by') String? get createdBy;/// Row creation timestamp.
@JsonKey(name: 'created_at') DateTime get createdAt;
/// Create a copy of Appointment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppointmentCopyWith<Appointment> get copyWith => _$AppointmentCopyWithImpl<Appointment>(this as Appointment, _$identity);

  /// Serializes this Appointment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Appointment&&(identical(other.id, id) || other.id == id)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.type, type) || other.type == type)&&(identical(other.scheduledAt, scheduledAt) || other.scheduledAt == scheduledAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.usePackage, usePackage) || other.usePackage == usePackage)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,patientId,type,scheduledAt,status,usePackage,createdBy,createdAt);

@override
String toString() {
  return 'Appointment(id: $id, patientId: $patientId, type: $type, scheduledAt: $scheduledAt, status: $status, usePackage: $usePackage, createdBy: $createdBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $AppointmentCopyWith<$Res>  {
  factory $AppointmentCopyWith(Appointment value, $Res Function(Appointment) _then) = _$AppointmentCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'patient_id') String patientId, AppointmentType type,@JsonKey(name: 'scheduled_at') DateTime scheduledAt, AppointmentStatus status,@JsonKey(name: 'use_package') bool usePackage,@JsonKey(name: 'created_by') String? createdBy,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class _$AppointmentCopyWithImpl<$Res>
    implements $AppointmentCopyWith<$Res> {
  _$AppointmentCopyWithImpl(this._self, this._then);

  final Appointment _self;
  final $Res Function(Appointment) _then;

/// Create a copy of Appointment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? patientId = null,Object? type = null,Object? scheduledAt = null,Object? status = null,Object? usePackage = null,Object? createdBy = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AppointmentType,scheduledAt: null == scheduledAt ? _self.scheduledAt : scheduledAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AppointmentStatus,usePackage: null == usePackage ? _self.usePackage : usePackage // ignore: cast_nullable_to_non_nullable
as bool,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Appointment].
extension AppointmentPatterns on Appointment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Appointment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Appointment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Appointment value)  $default,){
final _that = this;
switch (_that) {
case _Appointment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Appointment value)?  $default,){
final _that = this;
switch (_that) {
case _Appointment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'patient_id')  String patientId,  AppointmentType type, @JsonKey(name: 'scheduled_at')  DateTime scheduledAt,  AppointmentStatus status, @JsonKey(name: 'use_package')  bool usePackage, @JsonKey(name: 'created_by')  String? createdBy, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Appointment() when $default != null:
return $default(_that.id,_that.patientId,_that.type,_that.scheduledAt,_that.status,_that.usePackage,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'patient_id')  String patientId,  AppointmentType type, @JsonKey(name: 'scheduled_at')  DateTime scheduledAt,  AppointmentStatus status, @JsonKey(name: 'use_package')  bool usePackage, @JsonKey(name: 'created_by')  String? createdBy, @JsonKey(name: 'created_at')  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _Appointment():
return $default(_that.id,_that.patientId,_that.type,_that.scheduledAt,_that.status,_that.usePackage,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'patient_id')  String patientId,  AppointmentType type, @JsonKey(name: 'scheduled_at')  DateTime scheduledAt,  AppointmentStatus status, @JsonKey(name: 'use_package')  bool usePackage, @JsonKey(name: 'created_by')  String? createdBy, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Appointment() when $default != null:
return $default(_that.id,_that.patientId,_that.type,_that.scheduledAt,_that.status,_that.usePackage,_that.createdBy,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Appointment implements Appointment {
  const _Appointment({required this.id, @JsonKey(name: 'patient_id') required this.patientId, required this.type, @JsonKey(name: 'scheduled_at') required this.scheduledAt, this.status = AppointmentStatus.scheduled, @JsonKey(name: 'use_package') this.usePackage = true, @JsonKey(name: 'created_by') this.createdBy, @JsonKey(name: 'created_at') required this.createdAt});
  factory _Appointment.fromJson(Map<String, dynamic> json) => _$AppointmentFromJson(json);

/// Primary key (`uuid`).
@override final  String id;
/// FK references `patients(id)`.
@override@JsonKey(name: 'patient_id') final  String patientId;
/// Type of the appointment (session or traction device).
@override final  AppointmentType type;
/// Time the appointment is scheduled for.
@override@JsonKey(name: 'scheduled_at') final  DateTime scheduledAt;
/// Workflow status of the appointment.
@override@JsonKey() final  AppointmentStatus status;
/// Whether this appointment uses/deducts from the patient's package balance.
@override@JsonKey(name: 'use_package') final  bool usePackage;
/// FK references `staff(id)` representing the receptionist/admin who booked it.
@override@JsonKey(name: 'created_by') final  String? createdBy;
/// Row creation timestamp.
@override@JsonKey(name: 'created_at') final  DateTime createdAt;

/// Create a copy of Appointment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppointmentCopyWith<_Appointment> get copyWith => __$AppointmentCopyWithImpl<_Appointment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppointmentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Appointment&&(identical(other.id, id) || other.id == id)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.type, type) || other.type == type)&&(identical(other.scheduledAt, scheduledAt) || other.scheduledAt == scheduledAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.usePackage, usePackage) || other.usePackage == usePackage)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,patientId,type,scheduledAt,status,usePackage,createdBy,createdAt);

@override
String toString() {
  return 'Appointment(id: $id, patientId: $patientId, type: $type, scheduledAt: $scheduledAt, status: $status, usePackage: $usePackage, createdBy: $createdBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$AppointmentCopyWith<$Res> implements $AppointmentCopyWith<$Res> {
  factory _$AppointmentCopyWith(_Appointment value, $Res Function(_Appointment) _then) = __$AppointmentCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'patient_id') String patientId, AppointmentType type,@JsonKey(name: 'scheduled_at') DateTime scheduledAt, AppointmentStatus status,@JsonKey(name: 'use_package') bool usePackage,@JsonKey(name: 'created_by') String? createdBy,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class __$AppointmentCopyWithImpl<$Res>
    implements _$AppointmentCopyWith<$Res> {
  __$AppointmentCopyWithImpl(this._self, this._then);

  final _Appointment _self;
  final $Res Function(_Appointment) _then;

/// Create a copy of Appointment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? patientId = null,Object? type = null,Object? scheduledAt = null,Object? status = null,Object? usePackage = null,Object? createdBy = freezed,Object? createdAt = null,}) {
  return _then(_Appointment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AppointmentType,scheduledAt: null == scheduledAt ? _self.scheduledAt : scheduledAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AppointmentStatus,usePackage: null == usePackage ? _self.usePackage : usePackage // ignore: cast_nullable_to_non_nullable
as bool,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
