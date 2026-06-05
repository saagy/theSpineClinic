// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'clinic_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ClinicSettings {

 String get id; List<ClinicPackage> get packages;@JsonKey(name: 'updated_by') String? get updatedBy;@JsonKey(name: 'updated_at') DateTime get updatedAt;
/// Create a copy of ClinicSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClinicSettingsCopyWith<ClinicSettings> get copyWith => _$ClinicSettingsCopyWithImpl<ClinicSettings>(this as ClinicSettings, _$identity);

  /// Serializes this ClinicSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClinicSettings&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.packages, packages)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(packages),updatedBy,updatedAt);

@override
String toString() {
  return 'ClinicSettings(id: $id, packages: $packages, updatedBy: $updatedBy, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ClinicSettingsCopyWith<$Res>  {
  factory $ClinicSettingsCopyWith(ClinicSettings value, $Res Function(ClinicSettings) _then) = _$ClinicSettingsCopyWithImpl;
@useResult
$Res call({
 String id, List<ClinicPackage> packages,@JsonKey(name: 'updated_by') String? updatedBy,@JsonKey(name: 'updated_at') DateTime updatedAt
});




}
/// @nodoc
class _$ClinicSettingsCopyWithImpl<$Res>
    implements $ClinicSettingsCopyWith<$Res> {
  _$ClinicSettingsCopyWithImpl(this._self, this._then);

  final ClinicSettings _self;
  final $Res Function(ClinicSettings) _then;

/// Create a copy of ClinicSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? packages = null,Object? updatedBy = freezed,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,packages: null == packages ? _self.packages : packages // ignore: cast_nullable_to_non_nullable
as List<ClinicPackage>,updatedBy: freezed == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ClinicSettings].
extension ClinicSettingsPatterns on ClinicSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClinicSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClinicSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClinicSettings value)  $default,){
final _that = this;
switch (_that) {
case _ClinicSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClinicSettings value)?  $default,){
final _that = this;
switch (_that) {
case _ClinicSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  List<ClinicPackage> packages, @JsonKey(name: 'updated_by')  String? updatedBy, @JsonKey(name: 'updated_at')  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClinicSettings() when $default != null:
return $default(_that.id,_that.packages,_that.updatedBy,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  List<ClinicPackage> packages, @JsonKey(name: 'updated_by')  String? updatedBy, @JsonKey(name: 'updated_at')  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _ClinicSettings():
return $default(_that.id,_that.packages,_that.updatedBy,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  List<ClinicPackage> packages, @JsonKey(name: 'updated_by')  String? updatedBy, @JsonKey(name: 'updated_at')  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ClinicSettings() when $default != null:
return $default(_that.id,_that.packages,_that.updatedBy,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ClinicSettings implements ClinicSettings {
  const _ClinicSettings({required this.id, required final  List<ClinicPackage> packages, @JsonKey(name: 'updated_by') this.updatedBy, @JsonKey(name: 'updated_at') required this.updatedAt}): _packages = packages;
  factory _ClinicSettings.fromJson(Map<String, dynamic> json) => _$ClinicSettingsFromJson(json);

@override final  String id;
 final  List<ClinicPackage> _packages;
@override List<ClinicPackage> get packages {
  if (_packages is EqualUnmodifiableListView) return _packages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_packages);
}

@override@JsonKey(name: 'updated_by') final  String? updatedBy;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;

/// Create a copy of ClinicSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClinicSettingsCopyWith<_ClinicSettings> get copyWith => __$ClinicSettingsCopyWithImpl<_ClinicSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClinicSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClinicSettings&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other._packages, _packages)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_packages),updatedBy,updatedAt);

@override
String toString() {
  return 'ClinicSettings(id: $id, packages: $packages, updatedBy: $updatedBy, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ClinicSettingsCopyWith<$Res> implements $ClinicSettingsCopyWith<$Res> {
  factory _$ClinicSettingsCopyWith(_ClinicSettings value, $Res Function(_ClinicSettings) _then) = __$ClinicSettingsCopyWithImpl;
@override @useResult
$Res call({
 String id, List<ClinicPackage> packages,@JsonKey(name: 'updated_by') String? updatedBy,@JsonKey(name: 'updated_at') DateTime updatedAt
});




}
/// @nodoc
class __$ClinicSettingsCopyWithImpl<$Res>
    implements _$ClinicSettingsCopyWith<$Res> {
  __$ClinicSettingsCopyWithImpl(this._self, this._then);

  final _ClinicSettings _self;
  final $Res Function(_ClinicSettings) _then;

/// Create a copy of ClinicSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? packages = null,Object? updatedBy = freezed,Object? updatedAt = null,}) {
  return _then(_ClinicSettings(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,packages: null == packages ? _self._packages : packages // ignore: cast_nullable_to_non_nullable
as List<ClinicPackage>,updatedBy: freezed == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
