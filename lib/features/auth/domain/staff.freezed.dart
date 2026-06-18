// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'staff.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Staff {

/// Primary key (`uuid`).
 String get id;/// FK to `auth.users(id)` — nullable until the user completes sign-up.
@JsonKey(name: 'user_id') String? get userId;/// Display name shown across the application.
@JsonKey(name: 'full_name') String get fullName;/// Unique email address used for authentication.
 String get email;/// Phone number of the staff member.
 String? get phone;/// Access-control tier (super_admin / receptionist / doctor).
 UserRole get role;/// Whether the account has been approved by an admin.
@JsonKey(name: 'is_active') bool get isActive;/// The primary clinic location/branch for this staff member (synced preference).
@JsonKey(name: 'branch') ClinicLocation? get branch;/// Row creation timestamp.
@JsonKey(name: 'created_at') DateTime get createdAt;
/// Create a copy of Staff
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StaffCopyWith<Staff> get copyWith => _$StaffCopyWithImpl<Staff>(this as Staff, _$identity);

  /// Serializes this Staff to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Staff&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.role, role) || other.role == role)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.branch, branch) || other.branch == branch)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,fullName,email,phone,role,isActive,branch,createdAt);

@override
String toString() {
  return 'Staff(id: $id, userId: $userId, fullName: $fullName, email: $email, phone: $phone, role: $role, isActive: $isActive, branch: $branch, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $StaffCopyWith<$Res>  {
  factory $StaffCopyWith(Staff value, $Res Function(Staff) _then) = _$StaffCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String? userId,@JsonKey(name: 'full_name') String fullName, String email, String? phone, UserRole role,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'branch') ClinicLocation? branch,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class _$StaffCopyWithImpl<$Res>
    implements $StaffCopyWith<$Res> {
  _$StaffCopyWithImpl(this._self, this._then);

  final Staff _self;
  final $Res Function(Staff) _then;

/// Create a copy of Staff
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = freezed,Object? fullName = null,Object? email = null,Object? phone = freezed,Object? role = null,Object? isActive = null,Object? branch = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,branch: freezed == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as ClinicLocation?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Staff].
extension StaffPatterns on Staff {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Staff value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Staff() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Staff value)  $default,){
final _that = this;
switch (_that) {
case _Staff():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Staff value)?  $default,){
final _that = this;
switch (_that) {
case _Staff() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String? userId, @JsonKey(name: 'full_name')  String fullName,  String email,  String? phone,  UserRole role, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'branch')  ClinicLocation? branch, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Staff() when $default != null:
return $default(_that.id,_that.userId,_that.fullName,_that.email,_that.phone,_that.role,_that.isActive,_that.branch,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String? userId, @JsonKey(name: 'full_name')  String fullName,  String email,  String? phone,  UserRole role, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'branch')  ClinicLocation? branch, @JsonKey(name: 'created_at')  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _Staff():
return $default(_that.id,_that.userId,_that.fullName,_that.email,_that.phone,_that.role,_that.isActive,_that.branch,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'user_id')  String? userId, @JsonKey(name: 'full_name')  String fullName,  String email,  String? phone,  UserRole role, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'branch')  ClinicLocation? branch, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Staff() when $default != null:
return $default(_that.id,_that.userId,_that.fullName,_that.email,_that.phone,_that.role,_that.isActive,_that.branch,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Staff implements Staff {
  const _Staff({required this.id, @JsonKey(name: 'user_id') this.userId, @JsonKey(name: 'full_name') required this.fullName, required this.email, this.phone, required this.role, @JsonKey(name: 'is_active') this.isActive = true, @JsonKey(name: 'branch') this.branch, @JsonKey(name: 'created_at') required this.createdAt});
  factory _Staff.fromJson(Map<String, dynamic> json) => _$StaffFromJson(json);

/// Primary key (`uuid`).
@override final  String id;
/// FK to `auth.users(id)` — nullable until the user completes sign-up.
@override@JsonKey(name: 'user_id') final  String? userId;
/// Display name shown across the application.
@override@JsonKey(name: 'full_name') final  String fullName;
/// Unique email address used for authentication.
@override final  String email;
/// Phone number of the staff member.
@override final  String? phone;
/// Access-control tier (super_admin / receptionist / doctor).
@override final  UserRole role;
/// Whether the account has been approved by an admin.
@override@JsonKey(name: 'is_active') final  bool isActive;
/// The primary clinic location/branch for this staff member (synced preference).
@override@JsonKey(name: 'branch') final  ClinicLocation? branch;
/// Row creation timestamp.
@override@JsonKey(name: 'created_at') final  DateTime createdAt;

/// Create a copy of Staff
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StaffCopyWith<_Staff> get copyWith => __$StaffCopyWithImpl<_Staff>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StaffToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Staff&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.role, role) || other.role == role)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.branch, branch) || other.branch == branch)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,fullName,email,phone,role,isActive,branch,createdAt);

@override
String toString() {
  return 'Staff(id: $id, userId: $userId, fullName: $fullName, email: $email, phone: $phone, role: $role, isActive: $isActive, branch: $branch, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$StaffCopyWith<$Res> implements $StaffCopyWith<$Res> {
  factory _$StaffCopyWith(_Staff value, $Res Function(_Staff) _then) = __$StaffCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String? userId,@JsonKey(name: 'full_name') String fullName, String email, String? phone, UserRole role,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'branch') ClinicLocation? branch,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class __$StaffCopyWithImpl<$Res>
    implements _$StaffCopyWith<$Res> {
  __$StaffCopyWithImpl(this._self, this._then);

  final _Staff _self;
  final $Res Function(_Staff) _then;

/// Create a copy of Staff
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = freezed,Object? fullName = null,Object? email = null,Object? phone = freezed,Object? role = null,Object? isActive = null,Object? branch = freezed,Object? createdAt = null,}) {
  return _then(_Staff(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,branch: freezed == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as ClinicLocation?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
