// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'clinic_package.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ClinicPackage {

 String get name;@JsonKey(name: 'session_count') int get sessionCount;@JsonKey(fromJson: _priceFromJson, toJson: _priceToJson) double get price;
/// Create a copy of ClinicPackage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClinicPackageCopyWith<ClinicPackage> get copyWith => _$ClinicPackageCopyWithImpl<ClinicPackage>(this as ClinicPackage, _$identity);

  /// Serializes this ClinicPackage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClinicPackage&&(identical(other.name, name) || other.name == name)&&(identical(other.sessionCount, sessionCount) || other.sessionCount == sessionCount)&&(identical(other.price, price) || other.price == price));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,sessionCount,price);

@override
String toString() {
  return 'ClinicPackage(name: $name, sessionCount: $sessionCount, price: $price)';
}


}

/// @nodoc
abstract mixin class $ClinicPackageCopyWith<$Res>  {
  factory $ClinicPackageCopyWith(ClinicPackage value, $Res Function(ClinicPackage) _then) = _$ClinicPackageCopyWithImpl;
@useResult
$Res call({
 String name,@JsonKey(name: 'session_count') int sessionCount,@JsonKey(fromJson: _priceFromJson, toJson: _priceToJson) double price
});




}
/// @nodoc
class _$ClinicPackageCopyWithImpl<$Res>
    implements $ClinicPackageCopyWith<$Res> {
  _$ClinicPackageCopyWithImpl(this._self, this._then);

  final ClinicPackage _self;
  final $Res Function(ClinicPackage) _then;

/// Create a copy of ClinicPackage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? sessionCount = null,Object? price = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sessionCount: null == sessionCount ? _self.sessionCount : sessionCount // ignore: cast_nullable_to_non_nullable
as int,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ClinicPackage].
extension ClinicPackagePatterns on ClinicPackage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClinicPackage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClinicPackage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClinicPackage value)  $default,){
final _that = this;
switch (_that) {
case _ClinicPackage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClinicPackage value)?  $default,){
final _that = this;
switch (_that) {
case _ClinicPackage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name, @JsonKey(name: 'session_count')  int sessionCount, @JsonKey(fromJson: _priceFromJson, toJson: _priceToJson)  double price)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClinicPackage() when $default != null:
return $default(_that.name,_that.sessionCount,_that.price);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name, @JsonKey(name: 'session_count')  int sessionCount, @JsonKey(fromJson: _priceFromJson, toJson: _priceToJson)  double price)  $default,) {final _that = this;
switch (_that) {
case _ClinicPackage():
return $default(_that.name,_that.sessionCount,_that.price);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name, @JsonKey(name: 'session_count')  int sessionCount, @JsonKey(fromJson: _priceFromJson, toJson: _priceToJson)  double price)?  $default,) {final _that = this;
switch (_that) {
case _ClinicPackage() when $default != null:
return $default(_that.name,_that.sessionCount,_that.price);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ClinicPackage implements ClinicPackage {
  const _ClinicPackage({required this.name, @JsonKey(name: 'session_count') required this.sessionCount, @JsonKey(fromJson: _priceFromJson, toJson: _priceToJson) required this.price});
  factory _ClinicPackage.fromJson(Map<String, dynamic> json) => _$ClinicPackageFromJson(json);

@override final  String name;
@override@JsonKey(name: 'session_count') final  int sessionCount;
@override@JsonKey(fromJson: _priceFromJson, toJson: _priceToJson) final  double price;

/// Create a copy of ClinicPackage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClinicPackageCopyWith<_ClinicPackage> get copyWith => __$ClinicPackageCopyWithImpl<_ClinicPackage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClinicPackageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClinicPackage&&(identical(other.name, name) || other.name == name)&&(identical(other.sessionCount, sessionCount) || other.sessionCount == sessionCount)&&(identical(other.price, price) || other.price == price));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,sessionCount,price);

@override
String toString() {
  return 'ClinicPackage(name: $name, sessionCount: $sessionCount, price: $price)';
}


}

/// @nodoc
abstract mixin class _$ClinicPackageCopyWith<$Res> implements $ClinicPackageCopyWith<$Res> {
  factory _$ClinicPackageCopyWith(_ClinicPackage value, $Res Function(_ClinicPackage) _then) = __$ClinicPackageCopyWithImpl;
@override @useResult
$Res call({
 String name,@JsonKey(name: 'session_count') int sessionCount,@JsonKey(fromJson: _priceFromJson, toJson: _priceToJson) double price
});




}
/// @nodoc
class __$ClinicPackageCopyWithImpl<$Res>
    implements _$ClinicPackageCopyWith<$Res> {
  __$ClinicPackageCopyWithImpl(this._self, this._then);

  final _ClinicPackage _self;
  final $Res Function(_ClinicPackage) _then;

/// Create a copy of ClinicPackage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? sessionCount = null,Object? price = null,}) {
  return _then(_ClinicPackage(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sessionCount: null == sessionCount ? _self.sessionCount : sessionCount // ignore: cast_nullable_to_non_nullable
as int,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
