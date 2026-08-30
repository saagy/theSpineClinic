// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'plan_modality.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlanModality {

 String get id;@JsonKey(name: 'treatment_plan_id') String get treatmentPlanId;@JsonKey(name: 'modality_type') ModalityType get modalityType; String? get notes;@JsonKey(name: 'modality_regions') List<ModalityRegion> get regions;
/// Create a copy of PlanModality
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanModalityCopyWith<PlanModality> get copyWith => _$PlanModalityCopyWithImpl<PlanModality>(this as PlanModality, _$identity);

  /// Serializes this PlanModality to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanModality&&(identical(other.id, id) || other.id == id)&&(identical(other.treatmentPlanId, treatmentPlanId) || other.treatmentPlanId == treatmentPlanId)&&(identical(other.modalityType, modalityType) || other.modalityType == modalityType)&&(identical(other.notes, notes) || other.notes == notes)&&const DeepCollectionEquality().equals(other.regions, regions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,treatmentPlanId,modalityType,notes,const DeepCollectionEquality().hash(regions));

@override
String toString() {
  return 'PlanModality(id: $id, treatmentPlanId: $treatmentPlanId, modalityType: $modalityType, notes: $notes, regions: $regions)';
}


}

/// @nodoc
abstract mixin class $PlanModalityCopyWith<$Res>  {
  factory $PlanModalityCopyWith(PlanModality value, $Res Function(PlanModality) _then) = _$PlanModalityCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'treatment_plan_id') String treatmentPlanId,@JsonKey(name: 'modality_type') ModalityType modalityType, String? notes,@JsonKey(name: 'modality_regions') List<ModalityRegion> regions
});




}
/// @nodoc
class _$PlanModalityCopyWithImpl<$Res>
    implements $PlanModalityCopyWith<$Res> {
  _$PlanModalityCopyWithImpl(this._self, this._then);

  final PlanModality _self;
  final $Res Function(PlanModality) _then;

/// Create a copy of PlanModality
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? treatmentPlanId = null,Object? modalityType = null,Object? notes = freezed,Object? regions = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,treatmentPlanId: null == treatmentPlanId ? _self.treatmentPlanId : treatmentPlanId // ignore: cast_nullable_to_non_nullable
as String,modalityType: null == modalityType ? _self.modalityType : modalityType // ignore: cast_nullable_to_non_nullable
as ModalityType,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,regions: null == regions ? _self.regions : regions // ignore: cast_nullable_to_non_nullable
as List<ModalityRegion>,
  ));
}

}


/// Adds pattern-matching-related methods to [PlanModality].
extension PlanModalityPatterns on PlanModality {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlanModality value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlanModality() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlanModality value)  $default,){
final _that = this;
switch (_that) {
case _PlanModality():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlanModality value)?  $default,){
final _that = this;
switch (_that) {
case _PlanModality() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'treatment_plan_id')  String treatmentPlanId, @JsonKey(name: 'modality_type')  ModalityType modalityType,  String? notes, @JsonKey(name: 'modality_regions')  List<ModalityRegion> regions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlanModality() when $default != null:
return $default(_that.id,_that.treatmentPlanId,_that.modalityType,_that.notes,_that.regions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'treatment_plan_id')  String treatmentPlanId, @JsonKey(name: 'modality_type')  ModalityType modalityType,  String? notes, @JsonKey(name: 'modality_regions')  List<ModalityRegion> regions)  $default,) {final _that = this;
switch (_that) {
case _PlanModality():
return $default(_that.id,_that.treatmentPlanId,_that.modalityType,_that.notes,_that.regions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'treatment_plan_id')  String treatmentPlanId, @JsonKey(name: 'modality_type')  ModalityType modalityType,  String? notes, @JsonKey(name: 'modality_regions')  List<ModalityRegion> regions)?  $default,) {final _that = this;
switch (_that) {
case _PlanModality() when $default != null:
return $default(_that.id,_that.treatmentPlanId,_that.modalityType,_that.notes,_that.regions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlanModality implements PlanModality {
  const _PlanModality({required this.id, @JsonKey(name: 'treatment_plan_id') required this.treatmentPlanId, @JsonKey(name: 'modality_type') required this.modalityType, this.notes, @JsonKey(name: 'modality_regions') final  List<ModalityRegion> regions = const []}): _regions = regions;
  factory _PlanModality.fromJson(Map<String, dynamic> json) => _$PlanModalityFromJson(json);

@override final  String id;
@override@JsonKey(name: 'treatment_plan_id') final  String treatmentPlanId;
@override@JsonKey(name: 'modality_type') final  ModalityType modalityType;
@override final  String? notes;
 final  List<ModalityRegion> _regions;
@override@JsonKey(name: 'modality_regions') List<ModalityRegion> get regions {
  if (_regions is EqualUnmodifiableListView) return _regions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_regions);
}


/// Create a copy of PlanModality
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlanModalityCopyWith<_PlanModality> get copyWith => __$PlanModalityCopyWithImpl<_PlanModality>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlanModalityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlanModality&&(identical(other.id, id) || other.id == id)&&(identical(other.treatmentPlanId, treatmentPlanId) || other.treatmentPlanId == treatmentPlanId)&&(identical(other.modalityType, modalityType) || other.modalityType == modalityType)&&(identical(other.notes, notes) || other.notes == notes)&&const DeepCollectionEquality().equals(other._regions, _regions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,treatmentPlanId,modalityType,notes,const DeepCollectionEquality().hash(_regions));

@override
String toString() {
  return 'PlanModality(id: $id, treatmentPlanId: $treatmentPlanId, modalityType: $modalityType, notes: $notes, regions: $regions)';
}


}

/// @nodoc
abstract mixin class _$PlanModalityCopyWith<$Res> implements $PlanModalityCopyWith<$Res> {
  factory _$PlanModalityCopyWith(_PlanModality value, $Res Function(_PlanModality) _then) = __$PlanModalityCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'treatment_plan_id') String treatmentPlanId,@JsonKey(name: 'modality_type') ModalityType modalityType, String? notes,@JsonKey(name: 'modality_regions') List<ModalityRegion> regions
});




}
/// @nodoc
class __$PlanModalityCopyWithImpl<$Res>
    implements _$PlanModalityCopyWith<$Res> {
  __$PlanModalityCopyWithImpl(this._self, this._then);

  final _PlanModality _self;
  final $Res Function(_PlanModality) _then;

/// Create a copy of PlanModality
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? treatmentPlanId = null,Object? modalityType = null,Object? notes = freezed,Object? regions = null,}) {
  return _then(_PlanModality(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,treatmentPlanId: null == treatmentPlanId ? _self.treatmentPlanId : treatmentPlanId // ignore: cast_nullable_to_non_nullable
as String,modalityType: null == modalityType ? _self.modalityType : modalityType // ignore: cast_nullable_to_non_nullable
as ModalityType,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,regions: null == regions ? _self._regions : regions // ignore: cast_nullable_to_non_nullable
as List<ModalityRegion>,
  ));
}


}

// dart format on
