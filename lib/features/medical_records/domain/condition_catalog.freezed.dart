// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'condition_catalog.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ConditionCatalog {

 String get id; BodyRegion get region;@JsonKey(name: 'condition_name') String get conditionName;@JsonKey(name: 'display_order') int get displayOrder;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of ConditionCatalog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConditionCatalogCopyWith<ConditionCatalog> get copyWith => _$ConditionCatalogCopyWithImpl<ConditionCatalog>(this as ConditionCatalog, _$identity);

  /// Serializes this ConditionCatalog to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConditionCatalog&&(identical(other.id, id) || other.id == id)&&(identical(other.region, region) || other.region == region)&&(identical(other.conditionName, conditionName) || other.conditionName == conditionName)&&(identical(other.displayOrder, displayOrder) || other.displayOrder == displayOrder)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,region,conditionName,displayOrder,createdAt);

@override
String toString() {
  return 'ConditionCatalog(id: $id, region: $region, conditionName: $conditionName, displayOrder: $displayOrder, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ConditionCatalogCopyWith<$Res>  {
  factory $ConditionCatalogCopyWith(ConditionCatalog value, $Res Function(ConditionCatalog) _then) = _$ConditionCatalogCopyWithImpl;
@useResult
$Res call({
 String id, BodyRegion region,@JsonKey(name: 'condition_name') String conditionName,@JsonKey(name: 'display_order') int displayOrder,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class _$ConditionCatalogCopyWithImpl<$Res>
    implements $ConditionCatalogCopyWith<$Res> {
  _$ConditionCatalogCopyWithImpl(this._self, this._then);

  final ConditionCatalog _self;
  final $Res Function(ConditionCatalog) _then;

/// Create a copy of ConditionCatalog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? region = null,Object? conditionName = null,Object? displayOrder = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,region: null == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as BodyRegion,conditionName: null == conditionName ? _self.conditionName : conditionName // ignore: cast_nullable_to_non_nullable
as String,displayOrder: null == displayOrder ? _self.displayOrder : displayOrder // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ConditionCatalog].
extension ConditionCatalogPatterns on ConditionCatalog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConditionCatalog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConditionCatalog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConditionCatalog value)  $default,){
final _that = this;
switch (_that) {
case _ConditionCatalog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConditionCatalog value)?  $default,){
final _that = this;
switch (_that) {
case _ConditionCatalog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  BodyRegion region, @JsonKey(name: 'condition_name')  String conditionName, @JsonKey(name: 'display_order')  int displayOrder, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConditionCatalog() when $default != null:
return $default(_that.id,_that.region,_that.conditionName,_that.displayOrder,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  BodyRegion region, @JsonKey(name: 'condition_name')  String conditionName, @JsonKey(name: 'display_order')  int displayOrder, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _ConditionCatalog():
return $default(_that.id,_that.region,_that.conditionName,_that.displayOrder,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  BodyRegion region, @JsonKey(name: 'condition_name')  String conditionName, @JsonKey(name: 'display_order')  int displayOrder, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ConditionCatalog() when $default != null:
return $default(_that.id,_that.region,_that.conditionName,_that.displayOrder,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ConditionCatalog implements ConditionCatalog {
  const _ConditionCatalog({required this.id, required this.region, @JsonKey(name: 'condition_name') required this.conditionName, @JsonKey(name: 'display_order') this.displayOrder = 0, @JsonKey(name: 'created_at') this.createdAt});
  factory _ConditionCatalog.fromJson(Map<String, dynamic> json) => _$ConditionCatalogFromJson(json);

@override final  String id;
@override final  BodyRegion region;
@override@JsonKey(name: 'condition_name') final  String conditionName;
@override@JsonKey(name: 'display_order') final  int displayOrder;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of ConditionCatalog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConditionCatalogCopyWith<_ConditionCatalog> get copyWith => __$ConditionCatalogCopyWithImpl<_ConditionCatalog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConditionCatalogToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConditionCatalog&&(identical(other.id, id) || other.id == id)&&(identical(other.region, region) || other.region == region)&&(identical(other.conditionName, conditionName) || other.conditionName == conditionName)&&(identical(other.displayOrder, displayOrder) || other.displayOrder == displayOrder)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,region,conditionName,displayOrder,createdAt);

@override
String toString() {
  return 'ConditionCatalog(id: $id, region: $region, conditionName: $conditionName, displayOrder: $displayOrder, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ConditionCatalogCopyWith<$Res> implements $ConditionCatalogCopyWith<$Res> {
  factory _$ConditionCatalogCopyWith(_ConditionCatalog value, $Res Function(_ConditionCatalog) _then) = __$ConditionCatalogCopyWithImpl;
@override @useResult
$Res call({
 String id, BodyRegion region,@JsonKey(name: 'condition_name') String conditionName,@JsonKey(name: 'display_order') int displayOrder,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class __$ConditionCatalogCopyWithImpl<$Res>
    implements _$ConditionCatalogCopyWith<$Res> {
  __$ConditionCatalogCopyWithImpl(this._self, this._then);

  final _ConditionCatalog _self;
  final $Res Function(_ConditionCatalog) _then;

/// Create a copy of ConditionCatalog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? region = null,Object? conditionName = null,Object? displayOrder = null,Object? createdAt = freezed,}) {
  return _then(_ConditionCatalog(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,region: null == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as BodyRegion,conditionName: null == conditionName ? _self.conditionName : conditionName // ignore: cast_nullable_to_non_nullable
as String,displayOrder: null == displayOrder ? _self.displayOrder : displayOrder // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
