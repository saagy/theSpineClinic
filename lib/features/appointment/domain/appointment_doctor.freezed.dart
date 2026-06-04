// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'appointment_doctor.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppointmentDoctor {

/// Primary key (`uuid`).
 String get id;/// FK references `appointments(id)`.
@JsonKey(name: 'appointment_id') String get appointmentId;/// FK references `staff(id)` (role must be doctor).
@JsonKey(name: 'doctor_id') String get doctorId;/// Whether this doctor is covering for another doctor.
@JsonKey(name: 'is_replacement') bool get isReplacement;/// FK references `staff(id)` representing the doctor who is absent.
///
/// Set to null when [isReplacement] is false.
@JsonKey(name: 'replaced_doctor_id') String? get replacedDoctorId;/// Whether this assignment is currently active.
///
/// Swapped out/replaced doctors are kept but marked as inactive (`false`).
@JsonKey(name: 'is_active') bool get isActive;/// FK references `staff(id)` representing the person who added this doctor assignment.
@JsonKey(name: 'added_by') String? get addedBy;/// Row creation timestamp.
@JsonKey(name: 'added_at') DateTime get addedAt;
/// Create a copy of AppointmentDoctor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppointmentDoctorCopyWith<AppointmentDoctor> get copyWith => _$AppointmentDoctorCopyWithImpl<AppointmentDoctor>(this as AppointmentDoctor, _$identity);

  /// Serializes this AppointmentDoctor to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppointmentDoctor&&(identical(other.id, id) || other.id == id)&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&(identical(other.doctorId, doctorId) || other.doctorId == doctorId)&&(identical(other.isReplacement, isReplacement) || other.isReplacement == isReplacement)&&(identical(other.replacedDoctorId, replacedDoctorId) || other.replacedDoctorId == replacedDoctorId)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.addedBy, addedBy) || other.addedBy == addedBy)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,appointmentId,doctorId,isReplacement,replacedDoctorId,isActive,addedBy,addedAt);

@override
String toString() {
  return 'AppointmentDoctor(id: $id, appointmentId: $appointmentId, doctorId: $doctorId, isReplacement: $isReplacement, replacedDoctorId: $replacedDoctorId, isActive: $isActive, addedBy: $addedBy, addedAt: $addedAt)';
}


}

/// @nodoc
abstract mixin class $AppointmentDoctorCopyWith<$Res>  {
  factory $AppointmentDoctorCopyWith(AppointmentDoctor value, $Res Function(AppointmentDoctor) _then) = _$AppointmentDoctorCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'appointment_id') String appointmentId,@JsonKey(name: 'doctor_id') String doctorId,@JsonKey(name: 'is_replacement') bool isReplacement,@JsonKey(name: 'replaced_doctor_id') String? replacedDoctorId,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'added_by') String? addedBy,@JsonKey(name: 'added_at') DateTime addedAt
});




}
/// @nodoc
class _$AppointmentDoctorCopyWithImpl<$Res>
    implements $AppointmentDoctorCopyWith<$Res> {
  _$AppointmentDoctorCopyWithImpl(this._self, this._then);

  final AppointmentDoctor _self;
  final $Res Function(AppointmentDoctor) _then;

/// Create a copy of AppointmentDoctor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? appointmentId = null,Object? doctorId = null,Object? isReplacement = null,Object? replacedDoctorId = freezed,Object? isActive = null,Object? addedBy = freezed,Object? addedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,appointmentId: null == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String,doctorId: null == doctorId ? _self.doctorId : doctorId // ignore: cast_nullable_to_non_nullable
as String,isReplacement: null == isReplacement ? _self.isReplacement : isReplacement // ignore: cast_nullable_to_non_nullable
as bool,replacedDoctorId: freezed == replacedDoctorId ? _self.replacedDoctorId : replacedDoctorId // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,addedBy: freezed == addedBy ? _self.addedBy : addedBy // ignore: cast_nullable_to_non_nullable
as String?,addedAt: null == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [AppointmentDoctor].
extension AppointmentDoctorPatterns on AppointmentDoctor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppointmentDoctor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppointmentDoctor() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppointmentDoctor value)  $default,){
final _that = this;
switch (_that) {
case _AppointmentDoctor():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppointmentDoctor value)?  $default,){
final _that = this;
switch (_that) {
case _AppointmentDoctor() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'appointment_id')  String appointmentId, @JsonKey(name: 'doctor_id')  String doctorId, @JsonKey(name: 'is_replacement')  bool isReplacement, @JsonKey(name: 'replaced_doctor_id')  String? replacedDoctorId, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'added_by')  String? addedBy, @JsonKey(name: 'added_at')  DateTime addedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppointmentDoctor() when $default != null:
return $default(_that.id,_that.appointmentId,_that.doctorId,_that.isReplacement,_that.replacedDoctorId,_that.isActive,_that.addedBy,_that.addedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'appointment_id')  String appointmentId, @JsonKey(name: 'doctor_id')  String doctorId, @JsonKey(name: 'is_replacement')  bool isReplacement, @JsonKey(name: 'replaced_doctor_id')  String? replacedDoctorId, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'added_by')  String? addedBy, @JsonKey(name: 'added_at')  DateTime addedAt)  $default,) {final _that = this;
switch (_that) {
case _AppointmentDoctor():
return $default(_that.id,_that.appointmentId,_that.doctorId,_that.isReplacement,_that.replacedDoctorId,_that.isActive,_that.addedBy,_that.addedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'appointment_id')  String appointmentId, @JsonKey(name: 'doctor_id')  String doctorId, @JsonKey(name: 'is_replacement')  bool isReplacement, @JsonKey(name: 'replaced_doctor_id')  String? replacedDoctorId, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'added_by')  String? addedBy, @JsonKey(name: 'added_at')  DateTime addedAt)?  $default,) {final _that = this;
switch (_that) {
case _AppointmentDoctor() when $default != null:
return $default(_that.id,_that.appointmentId,_that.doctorId,_that.isReplacement,_that.replacedDoctorId,_that.isActive,_that.addedBy,_that.addedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppointmentDoctor implements AppointmentDoctor {
  const _AppointmentDoctor({required this.id, @JsonKey(name: 'appointment_id') required this.appointmentId, @JsonKey(name: 'doctor_id') required this.doctorId, @JsonKey(name: 'is_replacement') this.isReplacement = false, @JsonKey(name: 'replaced_doctor_id') this.replacedDoctorId, @JsonKey(name: 'is_active') this.isActive = true, @JsonKey(name: 'added_by') this.addedBy, @JsonKey(name: 'added_at') required this.addedAt});
  factory _AppointmentDoctor.fromJson(Map<String, dynamic> json) => _$AppointmentDoctorFromJson(json);

/// Primary key (`uuid`).
@override final  String id;
/// FK references `appointments(id)`.
@override@JsonKey(name: 'appointment_id') final  String appointmentId;
/// FK references `staff(id)` (role must be doctor).
@override@JsonKey(name: 'doctor_id') final  String doctorId;
/// Whether this doctor is covering for another doctor.
@override@JsonKey(name: 'is_replacement') final  bool isReplacement;
/// FK references `staff(id)` representing the doctor who is absent.
///
/// Set to null when [isReplacement] is false.
@override@JsonKey(name: 'replaced_doctor_id') final  String? replacedDoctorId;
/// Whether this assignment is currently active.
///
/// Swapped out/replaced doctors are kept but marked as inactive (`false`).
@override@JsonKey(name: 'is_active') final  bool isActive;
/// FK references `staff(id)` representing the person who added this doctor assignment.
@override@JsonKey(name: 'added_by') final  String? addedBy;
/// Row creation timestamp.
@override@JsonKey(name: 'added_at') final  DateTime addedAt;

/// Create a copy of AppointmentDoctor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppointmentDoctorCopyWith<_AppointmentDoctor> get copyWith => __$AppointmentDoctorCopyWithImpl<_AppointmentDoctor>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppointmentDoctorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppointmentDoctor&&(identical(other.id, id) || other.id == id)&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&(identical(other.doctorId, doctorId) || other.doctorId == doctorId)&&(identical(other.isReplacement, isReplacement) || other.isReplacement == isReplacement)&&(identical(other.replacedDoctorId, replacedDoctorId) || other.replacedDoctorId == replacedDoctorId)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.addedBy, addedBy) || other.addedBy == addedBy)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,appointmentId,doctorId,isReplacement,replacedDoctorId,isActive,addedBy,addedAt);

@override
String toString() {
  return 'AppointmentDoctor(id: $id, appointmentId: $appointmentId, doctorId: $doctorId, isReplacement: $isReplacement, replacedDoctorId: $replacedDoctorId, isActive: $isActive, addedBy: $addedBy, addedAt: $addedAt)';
}


}

/// @nodoc
abstract mixin class _$AppointmentDoctorCopyWith<$Res> implements $AppointmentDoctorCopyWith<$Res> {
  factory _$AppointmentDoctorCopyWith(_AppointmentDoctor value, $Res Function(_AppointmentDoctor) _then) = __$AppointmentDoctorCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'appointment_id') String appointmentId,@JsonKey(name: 'doctor_id') String doctorId,@JsonKey(name: 'is_replacement') bool isReplacement,@JsonKey(name: 'replaced_doctor_id') String? replacedDoctorId,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'added_by') String? addedBy,@JsonKey(name: 'added_at') DateTime addedAt
});




}
/// @nodoc
class __$AppointmentDoctorCopyWithImpl<$Res>
    implements _$AppointmentDoctorCopyWith<$Res> {
  __$AppointmentDoctorCopyWithImpl(this._self, this._then);

  final _AppointmentDoctor _self;
  final $Res Function(_AppointmentDoctor) _then;

/// Create a copy of AppointmentDoctor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? appointmentId = null,Object? doctorId = null,Object? isReplacement = null,Object? replacedDoctorId = freezed,Object? isActive = null,Object? addedBy = freezed,Object? addedAt = null,}) {
  return _then(_AppointmentDoctor(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,appointmentId: null == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String,doctorId: null == doctorId ? _self.doctorId : doctorId // ignore: cast_nullable_to_non_nullable
as String,isReplacement: null == isReplacement ? _self.isReplacement : isReplacement // ignore: cast_nullable_to_non_nullable
as bool,replacedDoctorId: freezed == replacedDoctorId ? _self.replacedDoctorId : replacedDoctorId // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,addedBy: freezed == addedBy ? _self.addedBy : addedBy // ignore: cast_nullable_to_non_nullable
as String?,addedAt: null == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
