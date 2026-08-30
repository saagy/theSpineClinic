// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'treatment_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TreatmentPlan {

 String get id;@JsonKey(name: 'program_id') String get programId;@JsonKey(name: 'created_by') String get createdBy;@JsonKey(name: 'plan_name') String get planName;@JsonKey(name: 'is_active') bool get isActive; String? get notes;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt;@JsonKey(name: 'plan_modalities') List<PlanModality> get modalities;
/// Create a copy of TreatmentPlan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TreatmentPlanCopyWith<TreatmentPlan> get copyWith => _$TreatmentPlanCopyWithImpl<TreatmentPlan>(this as TreatmentPlan, _$identity);

  /// Serializes this TreatmentPlan to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TreatmentPlan&&(identical(other.id, id) || other.id == id)&&(identical(other.programId, programId) || other.programId == programId)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.planName, planName) || other.planName == planName)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other.modalities, modalities));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,programId,createdBy,planName,isActive,notes,createdAt,updatedAt,const DeepCollectionEquality().hash(modalities));

@override
String toString() {
  return 'TreatmentPlan(id: $id, programId: $programId, createdBy: $createdBy, planName: $planName, isActive: $isActive, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt, modalities: $modalities)';
}


}

/// @nodoc
abstract mixin class $TreatmentPlanCopyWith<$Res>  {
  factory $TreatmentPlanCopyWith(TreatmentPlan value, $Res Function(TreatmentPlan) _then) = _$TreatmentPlanCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'program_id') String programId,@JsonKey(name: 'created_by') String createdBy,@JsonKey(name: 'plan_name') String planName,@JsonKey(name: 'is_active') bool isActive, String? notes,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'plan_modalities') List<PlanModality> modalities
});




}
/// @nodoc
class _$TreatmentPlanCopyWithImpl<$Res>
    implements $TreatmentPlanCopyWith<$Res> {
  _$TreatmentPlanCopyWithImpl(this._self, this._then);

  final TreatmentPlan _self;
  final $Res Function(TreatmentPlan) _then;

/// Create a copy of TreatmentPlan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? programId = null,Object? createdBy = null,Object? planName = null,Object? isActive = null,Object? notes = freezed,Object? createdAt = null,Object? updatedAt = null,Object? modalities = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,programId: null == programId ? _self.programId : programId // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,planName: null == planName ? _self.planName : planName // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,modalities: null == modalities ? _self.modalities : modalities // ignore: cast_nullable_to_non_nullable
as List<PlanModality>,
  ));
}

}


/// Adds pattern-matching-related methods to [TreatmentPlan].
extension TreatmentPlanPatterns on TreatmentPlan {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TreatmentPlan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TreatmentPlan() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TreatmentPlan value)  $default,){
final _that = this;
switch (_that) {
case _TreatmentPlan():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TreatmentPlan value)?  $default,){
final _that = this;
switch (_that) {
case _TreatmentPlan() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'program_id')  String programId, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'plan_name')  String planName, @JsonKey(name: 'is_active')  bool isActive,  String? notes, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'plan_modalities')  List<PlanModality> modalities)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TreatmentPlan() when $default != null:
return $default(_that.id,_that.programId,_that.createdBy,_that.planName,_that.isActive,_that.notes,_that.createdAt,_that.updatedAt,_that.modalities);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'program_id')  String programId, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'plan_name')  String planName, @JsonKey(name: 'is_active')  bool isActive,  String? notes, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'plan_modalities')  List<PlanModality> modalities)  $default,) {final _that = this;
switch (_that) {
case _TreatmentPlan():
return $default(_that.id,_that.programId,_that.createdBy,_that.planName,_that.isActive,_that.notes,_that.createdAt,_that.updatedAt,_that.modalities);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'program_id')  String programId, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'plan_name')  String planName, @JsonKey(name: 'is_active')  bool isActive,  String? notes, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'plan_modalities')  List<PlanModality> modalities)?  $default,) {final _that = this;
switch (_that) {
case _TreatmentPlan() when $default != null:
return $default(_that.id,_that.programId,_that.createdBy,_that.planName,_that.isActive,_that.notes,_that.createdAt,_that.updatedAt,_that.modalities);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TreatmentPlan implements TreatmentPlan {
  const _TreatmentPlan({required this.id, @JsonKey(name: 'program_id') required this.programId, @JsonKey(name: 'created_by') required this.createdBy, @JsonKey(name: 'plan_name') this.planName = 'Plan 1', @JsonKey(name: 'is_active') this.isActive = true, this.notes, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt, @JsonKey(name: 'plan_modalities') final  List<PlanModality> modalities = const []}): _modalities = modalities;
  factory _TreatmentPlan.fromJson(Map<String, dynamic> json) => _$TreatmentPlanFromJson(json);

@override final  String id;
@override@JsonKey(name: 'program_id') final  String programId;
@override@JsonKey(name: 'created_by') final  String createdBy;
@override@JsonKey(name: 'plan_name') final  String planName;
@override@JsonKey(name: 'is_active') final  bool isActive;
@override final  String? notes;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;
 final  List<PlanModality> _modalities;
@override@JsonKey(name: 'plan_modalities') List<PlanModality> get modalities {
  if (_modalities is EqualUnmodifiableListView) return _modalities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_modalities);
}


/// Create a copy of TreatmentPlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TreatmentPlanCopyWith<_TreatmentPlan> get copyWith => __$TreatmentPlanCopyWithImpl<_TreatmentPlan>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TreatmentPlanToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TreatmentPlan&&(identical(other.id, id) || other.id == id)&&(identical(other.programId, programId) || other.programId == programId)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.planName, planName) || other.planName == planName)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other._modalities, _modalities));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,programId,createdBy,planName,isActive,notes,createdAt,updatedAt,const DeepCollectionEquality().hash(_modalities));

@override
String toString() {
  return 'TreatmentPlan(id: $id, programId: $programId, createdBy: $createdBy, planName: $planName, isActive: $isActive, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt, modalities: $modalities)';
}


}

/// @nodoc
abstract mixin class _$TreatmentPlanCopyWith<$Res> implements $TreatmentPlanCopyWith<$Res> {
  factory _$TreatmentPlanCopyWith(_TreatmentPlan value, $Res Function(_TreatmentPlan) _then) = __$TreatmentPlanCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'program_id') String programId,@JsonKey(name: 'created_by') String createdBy,@JsonKey(name: 'plan_name') String planName,@JsonKey(name: 'is_active') bool isActive, String? notes,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'plan_modalities') List<PlanModality> modalities
});




}
/// @nodoc
class __$TreatmentPlanCopyWithImpl<$Res>
    implements _$TreatmentPlanCopyWith<$Res> {
  __$TreatmentPlanCopyWithImpl(this._self, this._then);

  final _TreatmentPlan _self;
  final $Res Function(_TreatmentPlan) _then;

/// Create a copy of TreatmentPlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? programId = null,Object? createdBy = null,Object? planName = null,Object? isActive = null,Object? notes = freezed,Object? createdAt = null,Object? updatedAt = null,Object? modalities = null,}) {
  return _then(_TreatmentPlan(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,programId: null == programId ? _self.programId : programId // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,planName: null == planName ? _self.planName : planName // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,modalities: null == modalities ? _self._modalities : modalities // ignore: cast_nullable_to_non_nullable
as List<PlanModality>,
  ));
}


}

// dart format on
