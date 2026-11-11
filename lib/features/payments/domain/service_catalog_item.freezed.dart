// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'service_catalog_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ServiceCatalogItem {

 String get id; String get name;@JsonKey(name: 'service_type', fromJson: _typeFromJson, toJson: _typeToJson) ServiceType get type;@JsonKey(name: 'sessions_per_unit') int get sessionsPerUnit;@JsonKey(name: 'price_minor') int get priceMinor;@JsonKey(name: 'attributes_doctors') bool get creditsDoctors; bool get active; int get version;
/// Create a copy of ServiceCatalogItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServiceCatalogItemCopyWith<ServiceCatalogItem> get copyWith => _$ServiceCatalogItemCopyWithImpl<ServiceCatalogItem>(this as ServiceCatalogItem, _$identity);

  /// Serializes this ServiceCatalogItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServiceCatalogItem&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.sessionsPerUnit, sessionsPerUnit) || other.sessionsPerUnit == sessionsPerUnit)&&(identical(other.priceMinor, priceMinor) || other.priceMinor == priceMinor)&&(identical(other.creditsDoctors, creditsDoctors) || other.creditsDoctors == creditsDoctors)&&(identical(other.active, active) || other.active == active)&&(identical(other.version, version) || other.version == version));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,sessionsPerUnit,priceMinor,creditsDoctors,active,version);

@override
String toString() {
  return 'ServiceCatalogItem(id: $id, name: $name, type: $type, sessionsPerUnit: $sessionsPerUnit, priceMinor: $priceMinor, creditsDoctors: $creditsDoctors, active: $active, version: $version)';
}


}

/// @nodoc
abstract mixin class $ServiceCatalogItemCopyWith<$Res>  {
  factory $ServiceCatalogItemCopyWith(ServiceCatalogItem value, $Res Function(ServiceCatalogItem) _then) = _$ServiceCatalogItemCopyWithImpl;
@useResult
$Res call({
 String id, String name,@JsonKey(name: 'service_type', fromJson: _typeFromJson, toJson: _typeToJson) ServiceType type,@JsonKey(name: 'sessions_per_unit') int sessionsPerUnit,@JsonKey(name: 'price_minor') int priceMinor,@JsonKey(name: 'attributes_doctors') bool creditsDoctors, bool active, int version
});




}
/// @nodoc
class _$ServiceCatalogItemCopyWithImpl<$Res>
    implements $ServiceCatalogItemCopyWith<$Res> {
  _$ServiceCatalogItemCopyWithImpl(this._self, this._then);

  final ServiceCatalogItem _self;
  final $Res Function(ServiceCatalogItem) _then;

/// Create a copy of ServiceCatalogItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = null,Object? sessionsPerUnit = null,Object? priceMinor = null,Object? creditsDoctors = null,Object? active = null,Object? version = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ServiceType,sessionsPerUnit: null == sessionsPerUnit ? _self.sessionsPerUnit : sessionsPerUnit // ignore: cast_nullable_to_non_nullable
as int,priceMinor: null == priceMinor ? _self.priceMinor : priceMinor // ignore: cast_nullable_to_non_nullable
as int,creditsDoctors: null == creditsDoctors ? _self.creditsDoctors : creditsDoctors // ignore: cast_nullable_to_non_nullable
as bool,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ServiceCatalogItem].
extension ServiceCatalogItemPatterns on ServiceCatalogItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServiceCatalogItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServiceCatalogItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServiceCatalogItem value)  $default,){
final _that = this;
switch (_that) {
case _ServiceCatalogItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServiceCatalogItem value)?  $default,){
final _that = this;
switch (_that) {
case _ServiceCatalogItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name, @JsonKey(name: 'service_type', fromJson: _typeFromJson, toJson: _typeToJson)  ServiceType type, @JsonKey(name: 'sessions_per_unit')  int sessionsPerUnit, @JsonKey(name: 'price_minor')  int priceMinor, @JsonKey(name: 'attributes_doctors')  bool creditsDoctors,  bool active,  int version)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServiceCatalogItem() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.sessionsPerUnit,_that.priceMinor,_that.creditsDoctors,_that.active,_that.version);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name, @JsonKey(name: 'service_type', fromJson: _typeFromJson, toJson: _typeToJson)  ServiceType type, @JsonKey(name: 'sessions_per_unit')  int sessionsPerUnit, @JsonKey(name: 'price_minor')  int priceMinor, @JsonKey(name: 'attributes_doctors')  bool creditsDoctors,  bool active,  int version)  $default,) {final _that = this;
switch (_that) {
case _ServiceCatalogItem():
return $default(_that.id,_that.name,_that.type,_that.sessionsPerUnit,_that.priceMinor,_that.creditsDoctors,_that.active,_that.version);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name, @JsonKey(name: 'service_type', fromJson: _typeFromJson, toJson: _typeToJson)  ServiceType type, @JsonKey(name: 'sessions_per_unit')  int sessionsPerUnit, @JsonKey(name: 'price_minor')  int priceMinor, @JsonKey(name: 'attributes_doctors')  bool creditsDoctors,  bool active,  int version)?  $default,) {final _that = this;
switch (_that) {
case _ServiceCatalogItem() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.sessionsPerUnit,_that.priceMinor,_that.creditsDoctors,_that.active,_that.version);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ServiceCatalogItem extends ServiceCatalogItem {
  const _ServiceCatalogItem({required this.id, required this.name, @JsonKey(name: 'service_type', fromJson: _typeFromJson, toJson: _typeToJson) required this.type, @JsonKey(name: 'sessions_per_unit') required this.sessionsPerUnit, @JsonKey(name: 'price_minor') required this.priceMinor, @JsonKey(name: 'attributes_doctors') required this.creditsDoctors, required this.active, required this.version}): super._();
  factory _ServiceCatalogItem.fromJson(Map<String, dynamic> json) => _$ServiceCatalogItemFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey(name: 'service_type', fromJson: _typeFromJson, toJson: _typeToJson) final  ServiceType type;
@override@JsonKey(name: 'sessions_per_unit') final  int sessionsPerUnit;
@override@JsonKey(name: 'price_minor') final  int priceMinor;
@override@JsonKey(name: 'attributes_doctors') final  bool creditsDoctors;
@override final  bool active;
@override final  int version;

/// Create a copy of ServiceCatalogItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServiceCatalogItemCopyWith<_ServiceCatalogItem> get copyWith => __$ServiceCatalogItemCopyWithImpl<_ServiceCatalogItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ServiceCatalogItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServiceCatalogItem&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.sessionsPerUnit, sessionsPerUnit) || other.sessionsPerUnit == sessionsPerUnit)&&(identical(other.priceMinor, priceMinor) || other.priceMinor == priceMinor)&&(identical(other.creditsDoctors, creditsDoctors) || other.creditsDoctors == creditsDoctors)&&(identical(other.active, active) || other.active == active)&&(identical(other.version, version) || other.version == version));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,sessionsPerUnit,priceMinor,creditsDoctors,active,version);

@override
String toString() {
  return 'ServiceCatalogItem(id: $id, name: $name, type: $type, sessionsPerUnit: $sessionsPerUnit, priceMinor: $priceMinor, creditsDoctors: $creditsDoctors, active: $active, version: $version)';
}


}

/// @nodoc
abstract mixin class _$ServiceCatalogItemCopyWith<$Res> implements $ServiceCatalogItemCopyWith<$Res> {
  factory _$ServiceCatalogItemCopyWith(_ServiceCatalogItem value, $Res Function(_ServiceCatalogItem) _then) = __$ServiceCatalogItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String name,@JsonKey(name: 'service_type', fromJson: _typeFromJson, toJson: _typeToJson) ServiceType type,@JsonKey(name: 'sessions_per_unit') int sessionsPerUnit,@JsonKey(name: 'price_minor') int priceMinor,@JsonKey(name: 'attributes_doctors') bool creditsDoctors, bool active, int version
});




}
/// @nodoc
class __$ServiceCatalogItemCopyWithImpl<$Res>
    implements _$ServiceCatalogItemCopyWith<$Res> {
  __$ServiceCatalogItemCopyWithImpl(this._self, this._then);

  final _ServiceCatalogItem _self;
  final $Res Function(_ServiceCatalogItem) _then;

/// Create a copy of ServiceCatalogItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = null,Object? sessionsPerUnit = null,Object? priceMinor = null,Object? creditsDoctors = null,Object? active = null,Object? version = null,}) {
  return _then(_ServiceCatalogItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ServiceType,sessionsPerUnit: null == sessionsPerUnit ? _self.sessionsPerUnit : sessionsPerUnit // ignore: cast_nullable_to_non_nullable
as int,priceMinor: null == priceMinor ? _self.priceMinor : priceMinor // ignore: cast_nullable_to_non_nullable
as int,creditsDoctors: null == creditsDoctors ? _self.creditsDoctors : creditsDoctors // ignore: cast_nullable_to_non_nullable
as bool,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
