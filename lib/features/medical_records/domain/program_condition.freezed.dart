// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'program_condition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProgramCondition {

 String get id;@JsonKey(name: 'program_id') String get programId;@JsonKey(name: 'condition_id') String get conditionId;@JsonKey(name: 'condition_catalog') ConditionCatalog? get condition;
/// Create a copy of ProgramCondition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProgramConditionCopyWith<ProgramCondition> get copyWith => _$ProgramConditionCopyWithImpl<ProgramCondition>(this as ProgramCondition, _$identity);

  /// Serializes this ProgramCondition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProgramCondition&&(identical(other.id, id) || other.id == id)&&(identical(other.programId, programId) || other.programId == programId)&&(identical(other.conditionId, conditionId) || other.conditionId == conditionId)&&(identical(other.condition, condition) || other.condition == condition));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,programId,conditionId,condition);

@override
String toString() {
  return 'ProgramCondition(id: $id, programId: $programId, conditionId: $conditionId, condition: $condition)';
}


}

/// @nodoc
abstract mixin class $ProgramConditionCopyWith<$Res>  {
  factory $ProgramConditionCopyWith(ProgramCondition value, $Res Function(ProgramCondition) _then) = _$ProgramConditionCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'program_id') String programId,@JsonKey(name: 'condition_id') String conditionId,@JsonKey(name: 'condition_catalog') ConditionCatalog? condition
});


$ConditionCatalogCopyWith<$Res>? get condition;

}
/// @nodoc
class _$ProgramConditionCopyWithImpl<$Res>
    implements $ProgramConditionCopyWith<$Res> {
  _$ProgramConditionCopyWithImpl(this._self, this._then);

  final ProgramCondition _self;
  final $Res Function(ProgramCondition) _then;

/// Create a copy of ProgramCondition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? programId = null,Object? conditionId = null,Object? condition = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,programId: null == programId ? _self.programId : programId // ignore: cast_nullable_to_non_nullable
as String,conditionId: null == conditionId ? _self.conditionId : conditionId // ignore: cast_nullable_to_non_nullable
as String,condition: freezed == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as ConditionCatalog?,
  ));
}
/// Create a copy of ProgramCondition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConditionCatalogCopyWith<$Res>? get condition {
    if (_self.condition == null) {
    return null;
  }

  return $ConditionCatalogCopyWith<$Res>(_self.condition!, (value) {
    return _then(_self.copyWith(condition: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProgramCondition].
extension ProgramConditionPatterns on ProgramCondition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProgramCondition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProgramCondition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProgramCondition value)  $default,){
final _that = this;
switch (_that) {
case _ProgramCondition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProgramCondition value)?  $default,){
final _that = this;
switch (_that) {
case _ProgramCondition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'program_id')  String programId, @JsonKey(name: 'condition_id')  String conditionId, @JsonKey(name: 'condition_catalog')  ConditionCatalog? condition)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProgramCondition() when $default != null:
return $default(_that.id,_that.programId,_that.conditionId,_that.condition);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'program_id')  String programId, @JsonKey(name: 'condition_id')  String conditionId, @JsonKey(name: 'condition_catalog')  ConditionCatalog? condition)  $default,) {final _that = this;
switch (_that) {
case _ProgramCondition():
return $default(_that.id,_that.programId,_that.conditionId,_that.condition);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'program_id')  String programId, @JsonKey(name: 'condition_id')  String conditionId, @JsonKey(name: 'condition_catalog')  ConditionCatalog? condition)?  $default,) {final _that = this;
switch (_that) {
case _ProgramCondition() when $default != null:
return $default(_that.id,_that.programId,_that.conditionId,_that.condition);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProgramCondition implements ProgramCondition {
  const _ProgramCondition({required this.id, @JsonKey(name: 'program_id') required this.programId, @JsonKey(name: 'condition_id') required this.conditionId, @JsonKey(name: 'condition_catalog') this.condition});
  factory _ProgramCondition.fromJson(Map<String, dynamic> json) => _$ProgramConditionFromJson(json);

@override final  String id;
@override@JsonKey(name: 'program_id') final  String programId;
@override@JsonKey(name: 'condition_id') final  String conditionId;
@override@JsonKey(name: 'condition_catalog') final  ConditionCatalog? condition;

/// Create a copy of ProgramCondition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProgramConditionCopyWith<_ProgramCondition> get copyWith => __$ProgramConditionCopyWithImpl<_ProgramCondition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProgramConditionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProgramCondition&&(identical(other.id, id) || other.id == id)&&(identical(other.programId, programId) || other.programId == programId)&&(identical(other.conditionId, conditionId) || other.conditionId == conditionId)&&(identical(other.condition, condition) || other.condition == condition));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,programId,conditionId,condition);

@override
String toString() {
  return 'ProgramCondition(id: $id, programId: $programId, conditionId: $conditionId, condition: $condition)';
}


}

/// @nodoc
abstract mixin class _$ProgramConditionCopyWith<$Res> implements $ProgramConditionCopyWith<$Res> {
  factory _$ProgramConditionCopyWith(_ProgramCondition value, $Res Function(_ProgramCondition) _then) = __$ProgramConditionCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'program_id') String programId,@JsonKey(name: 'condition_id') String conditionId,@JsonKey(name: 'condition_catalog') ConditionCatalog? condition
});


@override $ConditionCatalogCopyWith<$Res>? get condition;

}
/// @nodoc
class __$ProgramConditionCopyWithImpl<$Res>
    implements _$ProgramConditionCopyWith<$Res> {
  __$ProgramConditionCopyWithImpl(this._self, this._then);

  final _ProgramCondition _self;
  final $Res Function(_ProgramCondition) _then;

/// Create a copy of ProgramCondition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? programId = null,Object? conditionId = null,Object? condition = freezed,}) {
  return _then(_ProgramCondition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,programId: null == programId ? _self.programId : programId // ignore: cast_nullable_to_non_nullable
as String,conditionId: null == conditionId ? _self.conditionId : conditionId // ignore: cast_nullable_to_non_nullable
as String,condition: freezed == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as ConditionCatalog?,
  ));
}

/// Create a copy of ProgramCondition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConditionCatalogCopyWith<$Res>? get condition {
    if (_self.condition == null) {
    return null;
  }

  return $ConditionCatalogCopyWith<$Res>(_self.condition!, (value) {
    return _then(_self.copyWith(condition: value));
  });
}
}

// dart format on
