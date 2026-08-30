// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'modality_region.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ModalityRegion {

 String get id;@JsonKey(name: 'plan_modality_id') String get planModalityId;@JsonKey(name: 'target_region') String get targetRegion; Laterality? get laterality;@JsonKey(name: 'time_minutes') int get timeMinutes;
/// Create a copy of ModalityRegion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModalityRegionCopyWith<ModalityRegion> get copyWith => _$ModalityRegionCopyWithImpl<ModalityRegion>(this as ModalityRegion, _$identity);

  /// Serializes this ModalityRegion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModalityRegion&&(identical(other.id, id) || other.id == id)&&(identical(other.planModalityId, planModalityId) || other.planModalityId == planModalityId)&&(identical(other.targetRegion, targetRegion) || other.targetRegion == targetRegion)&&(identical(other.laterality, laterality) || other.laterality == laterality)&&(identical(other.timeMinutes, timeMinutes) || other.timeMinutes == timeMinutes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,planModalityId,targetRegion,laterality,timeMinutes);

@override
String toString() {
  return 'ModalityRegion(id: $id, planModalityId: $planModalityId, targetRegion: $targetRegion, laterality: $laterality, timeMinutes: $timeMinutes)';
}


}

/// @nodoc
abstract mixin class $ModalityRegionCopyWith<$Res>  {
  factory $ModalityRegionCopyWith(ModalityRegion value, $Res Function(ModalityRegion) _then) = _$ModalityRegionCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'plan_modality_id') String planModalityId,@JsonKey(name: 'target_region') String targetRegion, Laterality? laterality,@JsonKey(name: 'time_minutes') int timeMinutes
});




}
/// @nodoc
class _$ModalityRegionCopyWithImpl<$Res>
    implements $ModalityRegionCopyWith<$Res> {
  _$ModalityRegionCopyWithImpl(this._self, this._then);

  final ModalityRegion _self;
  final $Res Function(ModalityRegion) _then;

/// Create a copy of ModalityRegion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? planModalityId = null,Object? targetRegion = null,Object? laterality = freezed,Object? timeMinutes = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,planModalityId: null == planModalityId ? _self.planModalityId : planModalityId // ignore: cast_nullable_to_non_nullable
as String,targetRegion: null == targetRegion ? _self.targetRegion : targetRegion // ignore: cast_nullable_to_non_nullable
as String,laterality: freezed == laterality ? _self.laterality : laterality // ignore: cast_nullable_to_non_nullable
as Laterality?,timeMinutes: null == timeMinutes ? _self.timeMinutes : timeMinutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ModalityRegion].
extension ModalityRegionPatterns on ModalityRegion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModalityRegion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModalityRegion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModalityRegion value)  $default,){
final _that = this;
switch (_that) {
case _ModalityRegion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModalityRegion value)?  $default,){
final _that = this;
switch (_that) {
case _ModalityRegion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'plan_modality_id')  String planModalityId, @JsonKey(name: 'target_region')  String targetRegion,  Laterality? laterality, @JsonKey(name: 'time_minutes')  int timeMinutes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModalityRegion() when $default != null:
return $default(_that.id,_that.planModalityId,_that.targetRegion,_that.laterality,_that.timeMinutes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'plan_modality_id')  String planModalityId, @JsonKey(name: 'target_region')  String targetRegion,  Laterality? laterality, @JsonKey(name: 'time_minutes')  int timeMinutes)  $default,) {final _that = this;
switch (_that) {
case _ModalityRegion():
return $default(_that.id,_that.planModalityId,_that.targetRegion,_that.laterality,_that.timeMinutes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'plan_modality_id')  String planModalityId, @JsonKey(name: 'target_region')  String targetRegion,  Laterality? laterality, @JsonKey(name: 'time_minutes')  int timeMinutes)?  $default,) {final _that = this;
switch (_that) {
case _ModalityRegion() when $default != null:
return $default(_that.id,_that.planModalityId,_that.targetRegion,_that.laterality,_that.timeMinutes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModalityRegion implements ModalityRegion {
  const _ModalityRegion({required this.id, @JsonKey(name: 'plan_modality_id') required this.planModalityId, @JsonKey(name: 'target_region') required this.targetRegion, this.laterality, @JsonKey(name: 'time_minutes') this.timeMinutes = 15});
  factory _ModalityRegion.fromJson(Map<String, dynamic> json) => _$ModalityRegionFromJson(json);

@override final  String id;
@override@JsonKey(name: 'plan_modality_id') final  String planModalityId;
@override@JsonKey(name: 'target_region') final  String targetRegion;
@override final  Laterality? laterality;
@override@JsonKey(name: 'time_minutes') final  int timeMinutes;

/// Create a copy of ModalityRegion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModalityRegionCopyWith<_ModalityRegion> get copyWith => __$ModalityRegionCopyWithImpl<_ModalityRegion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModalityRegionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModalityRegion&&(identical(other.id, id) || other.id == id)&&(identical(other.planModalityId, planModalityId) || other.planModalityId == planModalityId)&&(identical(other.targetRegion, targetRegion) || other.targetRegion == targetRegion)&&(identical(other.laterality, laterality) || other.laterality == laterality)&&(identical(other.timeMinutes, timeMinutes) || other.timeMinutes == timeMinutes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,planModalityId,targetRegion,laterality,timeMinutes);

@override
String toString() {
  return 'ModalityRegion(id: $id, planModalityId: $planModalityId, targetRegion: $targetRegion, laterality: $laterality, timeMinutes: $timeMinutes)';
}


}

/// @nodoc
abstract mixin class _$ModalityRegionCopyWith<$Res> implements $ModalityRegionCopyWith<$Res> {
  factory _$ModalityRegionCopyWith(_ModalityRegion value, $Res Function(_ModalityRegion) _then) = __$ModalityRegionCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'plan_modality_id') String planModalityId,@JsonKey(name: 'target_region') String targetRegion, Laterality? laterality,@JsonKey(name: 'time_minutes') int timeMinutes
});




}
/// @nodoc
class __$ModalityRegionCopyWithImpl<$Res>
    implements _$ModalityRegionCopyWith<$Res> {
  __$ModalityRegionCopyWithImpl(this._self, this._then);

  final _ModalityRegion _self;
  final $Res Function(_ModalityRegion) _then;

/// Create a copy of ModalityRegion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? planModalityId = null,Object? targetRegion = null,Object? laterality = freezed,Object? timeMinutes = null,}) {
  return _then(_ModalityRegion(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,planModalityId: null == planModalityId ? _self.planModalityId : planModalityId // ignore: cast_nullable_to_non_nullable
as String,targetRegion: null == targetRegion ? _self.targetRegion : targetRegion // ignore: cast_nullable_to_non_nullable
as String,laterality: freezed == laterality ? _self.laterality : laterality // ignore: cast_nullable_to_non_nullable
as Laterality?,timeMinutes: null == timeMinutes ? _self.timeMinutes : timeMinutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
