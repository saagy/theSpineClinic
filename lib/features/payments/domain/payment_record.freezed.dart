// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PaymentRecord {

 String get id;@JsonKey(name: 'patient_id') String get patientId;@JsonKey(fromJson: _amountFromJson, toJson: _amountToJson) double get amount; String get reason;@JsonKey(name: 'recorded_by') String? get recordedBy;@JsonKey(name: 'recorded_at') DateTime get recordedAt;/// Number of Normal PT sessions added to patient balance by this payment.
@JsonKey(name: 'session_balance_added') int get sessionBalanceAdded;/// Number of Spinal Traction sessions added to patient balance by this payment.
@JsonKey(name: 'traction_balance_added') int get tractionBalanceAdded;
/// Create a copy of PaymentRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentRecordCopyWith<PaymentRecord> get copyWith => _$PaymentRecordCopyWithImpl<PaymentRecord>(this as PaymentRecord, _$identity);

  /// Serializes this PaymentRecord to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.recordedBy, recordedBy) || other.recordedBy == recordedBy)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt)&&(identical(other.sessionBalanceAdded, sessionBalanceAdded) || other.sessionBalanceAdded == sessionBalanceAdded)&&(identical(other.tractionBalanceAdded, tractionBalanceAdded) || other.tractionBalanceAdded == tractionBalanceAdded));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,patientId,amount,reason,recordedBy,recordedAt,sessionBalanceAdded,tractionBalanceAdded);

@override
String toString() {
  return 'PaymentRecord(id: $id, patientId: $patientId, amount: $amount, reason: $reason, recordedBy: $recordedBy, recordedAt: $recordedAt, sessionBalanceAdded: $sessionBalanceAdded, tractionBalanceAdded: $tractionBalanceAdded)';
}


}

/// @nodoc
abstract mixin class $PaymentRecordCopyWith<$Res>  {
  factory $PaymentRecordCopyWith(PaymentRecord value, $Res Function(PaymentRecord) _then) = _$PaymentRecordCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'patient_id') String patientId,@JsonKey(fromJson: _amountFromJson, toJson: _amountToJson) double amount, String reason,@JsonKey(name: 'recorded_by') String? recordedBy,@JsonKey(name: 'recorded_at') DateTime recordedAt,@JsonKey(name: 'session_balance_added') int sessionBalanceAdded,@JsonKey(name: 'traction_balance_added') int tractionBalanceAdded
});




}
/// @nodoc
class _$PaymentRecordCopyWithImpl<$Res>
    implements $PaymentRecordCopyWith<$Res> {
  _$PaymentRecordCopyWithImpl(this._self, this._then);

  final PaymentRecord _self;
  final $Res Function(PaymentRecord) _then;

/// Create a copy of PaymentRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? patientId = null,Object? amount = null,Object? reason = null,Object? recordedBy = freezed,Object? recordedAt = null,Object? sessionBalanceAdded = null,Object? tractionBalanceAdded = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,recordedBy: freezed == recordedBy ? _self.recordedBy : recordedBy // ignore: cast_nullable_to_non_nullable
as String?,recordedAt: null == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime,sessionBalanceAdded: null == sessionBalanceAdded ? _self.sessionBalanceAdded : sessionBalanceAdded // ignore: cast_nullable_to_non_nullable
as int,tractionBalanceAdded: null == tractionBalanceAdded ? _self.tractionBalanceAdded : tractionBalanceAdded // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PaymentRecord].
extension PaymentRecordPatterns on PaymentRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaymentRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaymentRecord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaymentRecord value)  $default,){
final _that = this;
switch (_that) {
case _PaymentRecord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaymentRecord value)?  $default,){
final _that = this;
switch (_that) {
case _PaymentRecord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'patient_id')  String patientId, @JsonKey(fromJson: _amountFromJson, toJson: _amountToJson)  double amount,  String reason, @JsonKey(name: 'recorded_by')  String? recordedBy, @JsonKey(name: 'recorded_at')  DateTime recordedAt, @JsonKey(name: 'session_balance_added')  int sessionBalanceAdded, @JsonKey(name: 'traction_balance_added')  int tractionBalanceAdded)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaymentRecord() when $default != null:
return $default(_that.id,_that.patientId,_that.amount,_that.reason,_that.recordedBy,_that.recordedAt,_that.sessionBalanceAdded,_that.tractionBalanceAdded);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'patient_id')  String patientId, @JsonKey(fromJson: _amountFromJson, toJson: _amountToJson)  double amount,  String reason, @JsonKey(name: 'recorded_by')  String? recordedBy, @JsonKey(name: 'recorded_at')  DateTime recordedAt, @JsonKey(name: 'session_balance_added')  int sessionBalanceAdded, @JsonKey(name: 'traction_balance_added')  int tractionBalanceAdded)  $default,) {final _that = this;
switch (_that) {
case _PaymentRecord():
return $default(_that.id,_that.patientId,_that.amount,_that.reason,_that.recordedBy,_that.recordedAt,_that.sessionBalanceAdded,_that.tractionBalanceAdded);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'patient_id')  String patientId, @JsonKey(fromJson: _amountFromJson, toJson: _amountToJson)  double amount,  String reason, @JsonKey(name: 'recorded_by')  String? recordedBy, @JsonKey(name: 'recorded_at')  DateTime recordedAt, @JsonKey(name: 'session_balance_added')  int sessionBalanceAdded, @JsonKey(name: 'traction_balance_added')  int tractionBalanceAdded)?  $default,) {final _that = this;
switch (_that) {
case _PaymentRecord() when $default != null:
return $default(_that.id,_that.patientId,_that.amount,_that.reason,_that.recordedBy,_that.recordedAt,_that.sessionBalanceAdded,_that.tractionBalanceAdded);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaymentRecord implements PaymentRecord {
  const _PaymentRecord({required this.id, @JsonKey(name: 'patient_id') required this.patientId, @JsonKey(fromJson: _amountFromJson, toJson: _amountToJson) required this.amount, required this.reason, @JsonKey(name: 'recorded_by') this.recordedBy, @JsonKey(name: 'recorded_at') required this.recordedAt, @JsonKey(name: 'session_balance_added') this.sessionBalanceAdded = 0, @JsonKey(name: 'traction_balance_added') this.tractionBalanceAdded = 0});
  factory _PaymentRecord.fromJson(Map<String, dynamic> json) => _$PaymentRecordFromJson(json);

@override final  String id;
@override@JsonKey(name: 'patient_id') final  String patientId;
@override@JsonKey(fromJson: _amountFromJson, toJson: _amountToJson) final  double amount;
@override final  String reason;
@override@JsonKey(name: 'recorded_by') final  String? recordedBy;
@override@JsonKey(name: 'recorded_at') final  DateTime recordedAt;
/// Number of Normal PT sessions added to patient balance by this payment.
@override@JsonKey(name: 'session_balance_added') final  int sessionBalanceAdded;
/// Number of Spinal Traction sessions added to patient balance by this payment.
@override@JsonKey(name: 'traction_balance_added') final  int tractionBalanceAdded;

/// Create a copy of PaymentRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentRecordCopyWith<_PaymentRecord> get copyWith => __$PaymentRecordCopyWithImpl<_PaymentRecord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaymentRecordToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaymentRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.recordedBy, recordedBy) || other.recordedBy == recordedBy)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt)&&(identical(other.sessionBalanceAdded, sessionBalanceAdded) || other.sessionBalanceAdded == sessionBalanceAdded)&&(identical(other.tractionBalanceAdded, tractionBalanceAdded) || other.tractionBalanceAdded == tractionBalanceAdded));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,patientId,amount,reason,recordedBy,recordedAt,sessionBalanceAdded,tractionBalanceAdded);

@override
String toString() {
  return 'PaymentRecord(id: $id, patientId: $patientId, amount: $amount, reason: $reason, recordedBy: $recordedBy, recordedAt: $recordedAt, sessionBalanceAdded: $sessionBalanceAdded, tractionBalanceAdded: $tractionBalanceAdded)';
}


}

/// @nodoc
abstract mixin class _$PaymentRecordCopyWith<$Res> implements $PaymentRecordCopyWith<$Res> {
  factory _$PaymentRecordCopyWith(_PaymentRecord value, $Res Function(_PaymentRecord) _then) = __$PaymentRecordCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'patient_id') String patientId,@JsonKey(fromJson: _amountFromJson, toJson: _amountToJson) double amount, String reason,@JsonKey(name: 'recorded_by') String? recordedBy,@JsonKey(name: 'recorded_at') DateTime recordedAt,@JsonKey(name: 'session_balance_added') int sessionBalanceAdded,@JsonKey(name: 'traction_balance_added') int tractionBalanceAdded
});




}
/// @nodoc
class __$PaymentRecordCopyWithImpl<$Res>
    implements _$PaymentRecordCopyWith<$Res> {
  __$PaymentRecordCopyWithImpl(this._self, this._then);

  final _PaymentRecord _self;
  final $Res Function(_PaymentRecord) _then;

/// Create a copy of PaymentRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? patientId = null,Object? amount = null,Object? reason = null,Object? recordedBy = freezed,Object? recordedAt = null,Object? sessionBalanceAdded = null,Object? tractionBalanceAdded = null,}) {
  return _then(_PaymentRecord(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,recordedBy: freezed == recordedBy ? _self.recordedBy : recordedBy // ignore: cast_nullable_to_non_nullable
as String?,recordedAt: null == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime,sessionBalanceAdded: null == sessionBalanceAdded ? _self.sessionBalanceAdded : sessionBalanceAdded // ignore: cast_nullable_to_non_nullable
as int,tractionBalanceAdded: null == tractionBalanceAdded ? _self.tractionBalanceAdded : tractionBalanceAdded // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
