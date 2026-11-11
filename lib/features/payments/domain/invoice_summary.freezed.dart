// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invoice_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InvoiceSummary {

 String get id; ClinicLocation get branch; int get number;@JsonKey(name: 'patient_id') String get patientId;@JsonKey(name: 'invoice_date') DateTime get invoiceDate;@JsonKey(name: 'total_minor') int get totalMinor;@JsonKey(name: 'discount_minor') int get discountMinor;@JsonKey(name: 'value_minor') int get valueMinor;@JsonKey(name: 'net_collected_minor') int get collectedMinor;@JsonKey(name: 'due_minor') int get dueMinor;@JsonKey(name: 'refunded_minor') int get refundedMinor;@JsonKey(fromJson: _statusFromJson, toJson: _statusToJson) InvoiceStatus get status; String get services;@JsonKey(fromJson: _doctorsFromJson) List<String> get doctors;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'created_by_name') String get createdByName; int get version;
/// Create a copy of InvoiceSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvoiceSummaryCopyWith<InvoiceSummary> get copyWith => _$InvoiceSummaryCopyWithImpl<InvoiceSummary>(this as InvoiceSummary, _$identity);

  /// Serializes this InvoiceSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvoiceSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.branch, branch) || other.branch == branch)&&(identical(other.number, number) || other.number == number)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.invoiceDate, invoiceDate) || other.invoiceDate == invoiceDate)&&(identical(other.totalMinor, totalMinor) || other.totalMinor == totalMinor)&&(identical(other.discountMinor, discountMinor) || other.discountMinor == discountMinor)&&(identical(other.valueMinor, valueMinor) || other.valueMinor == valueMinor)&&(identical(other.collectedMinor, collectedMinor) || other.collectedMinor == collectedMinor)&&(identical(other.dueMinor, dueMinor) || other.dueMinor == dueMinor)&&(identical(other.refundedMinor, refundedMinor) || other.refundedMinor == refundedMinor)&&(identical(other.status, status) || other.status == status)&&(identical(other.services, services) || other.services == services)&&const DeepCollectionEquality().equals(other.doctors, doctors)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdByName, createdByName) || other.createdByName == createdByName)&&(identical(other.version, version) || other.version == version));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,branch,number,patientId,invoiceDate,totalMinor,discountMinor,valueMinor,collectedMinor,dueMinor,refundedMinor,status,services,const DeepCollectionEquality().hash(doctors),createdAt,createdByName,version);

@override
String toString() {
  return 'InvoiceSummary(id: $id, branch: $branch, number: $number, patientId: $patientId, invoiceDate: $invoiceDate, totalMinor: $totalMinor, discountMinor: $discountMinor, valueMinor: $valueMinor, collectedMinor: $collectedMinor, dueMinor: $dueMinor, refundedMinor: $refundedMinor, status: $status, services: $services, doctors: $doctors, createdAt: $createdAt, createdByName: $createdByName, version: $version)';
}


}

/// @nodoc
abstract mixin class $InvoiceSummaryCopyWith<$Res>  {
  factory $InvoiceSummaryCopyWith(InvoiceSummary value, $Res Function(InvoiceSummary) _then) = _$InvoiceSummaryCopyWithImpl;
@useResult
$Res call({
 String id, ClinicLocation branch, int number,@JsonKey(name: 'patient_id') String patientId,@JsonKey(name: 'invoice_date') DateTime invoiceDate,@JsonKey(name: 'total_minor') int totalMinor,@JsonKey(name: 'discount_minor') int discountMinor,@JsonKey(name: 'value_minor') int valueMinor,@JsonKey(name: 'net_collected_minor') int collectedMinor,@JsonKey(name: 'due_minor') int dueMinor,@JsonKey(name: 'refunded_minor') int refundedMinor,@JsonKey(fromJson: _statusFromJson, toJson: _statusToJson) InvoiceStatus status, String services,@JsonKey(fromJson: _doctorsFromJson) List<String> doctors,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'created_by_name') String createdByName, int version
});




}
/// @nodoc
class _$InvoiceSummaryCopyWithImpl<$Res>
    implements $InvoiceSummaryCopyWith<$Res> {
  _$InvoiceSummaryCopyWithImpl(this._self, this._then);

  final InvoiceSummary _self;
  final $Res Function(InvoiceSummary) _then;

/// Create a copy of InvoiceSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? branch = null,Object? number = null,Object? patientId = null,Object? invoiceDate = null,Object? totalMinor = null,Object? discountMinor = null,Object? valueMinor = null,Object? collectedMinor = null,Object? dueMinor = null,Object? refundedMinor = null,Object? status = null,Object? services = null,Object? doctors = null,Object? createdAt = null,Object? createdByName = null,Object? version = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,branch: null == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as ClinicLocation,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,invoiceDate: null == invoiceDate ? _self.invoiceDate : invoiceDate // ignore: cast_nullable_to_non_nullable
as DateTime,totalMinor: null == totalMinor ? _self.totalMinor : totalMinor // ignore: cast_nullable_to_non_nullable
as int,discountMinor: null == discountMinor ? _self.discountMinor : discountMinor // ignore: cast_nullable_to_non_nullable
as int,valueMinor: null == valueMinor ? _self.valueMinor : valueMinor // ignore: cast_nullable_to_non_nullable
as int,collectedMinor: null == collectedMinor ? _self.collectedMinor : collectedMinor // ignore: cast_nullable_to_non_nullable
as int,dueMinor: null == dueMinor ? _self.dueMinor : dueMinor // ignore: cast_nullable_to_non_nullable
as int,refundedMinor: null == refundedMinor ? _self.refundedMinor : refundedMinor // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InvoiceStatus,services: null == services ? _self.services : services // ignore: cast_nullable_to_non_nullable
as String,doctors: null == doctors ? _self.doctors : doctors // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdByName: null == createdByName ? _self.createdByName : createdByName // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [InvoiceSummary].
extension InvoiceSummaryPatterns on InvoiceSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InvoiceSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InvoiceSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InvoiceSummary value)  $default,){
final _that = this;
switch (_that) {
case _InvoiceSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InvoiceSummary value)?  $default,){
final _that = this;
switch (_that) {
case _InvoiceSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  ClinicLocation branch,  int number, @JsonKey(name: 'patient_id')  String patientId, @JsonKey(name: 'invoice_date')  DateTime invoiceDate, @JsonKey(name: 'total_minor')  int totalMinor, @JsonKey(name: 'discount_minor')  int discountMinor, @JsonKey(name: 'value_minor')  int valueMinor, @JsonKey(name: 'net_collected_minor')  int collectedMinor, @JsonKey(name: 'due_minor')  int dueMinor, @JsonKey(name: 'refunded_minor')  int refundedMinor, @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)  InvoiceStatus status,  String services, @JsonKey(fromJson: _doctorsFromJson)  List<String> doctors, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'created_by_name')  String createdByName,  int version)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InvoiceSummary() when $default != null:
return $default(_that.id,_that.branch,_that.number,_that.patientId,_that.invoiceDate,_that.totalMinor,_that.discountMinor,_that.valueMinor,_that.collectedMinor,_that.dueMinor,_that.refundedMinor,_that.status,_that.services,_that.doctors,_that.createdAt,_that.createdByName,_that.version);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  ClinicLocation branch,  int number, @JsonKey(name: 'patient_id')  String patientId, @JsonKey(name: 'invoice_date')  DateTime invoiceDate, @JsonKey(name: 'total_minor')  int totalMinor, @JsonKey(name: 'discount_minor')  int discountMinor, @JsonKey(name: 'value_minor')  int valueMinor, @JsonKey(name: 'net_collected_minor')  int collectedMinor, @JsonKey(name: 'due_minor')  int dueMinor, @JsonKey(name: 'refunded_minor')  int refundedMinor, @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)  InvoiceStatus status,  String services, @JsonKey(fromJson: _doctorsFromJson)  List<String> doctors, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'created_by_name')  String createdByName,  int version)  $default,) {final _that = this;
switch (_that) {
case _InvoiceSummary():
return $default(_that.id,_that.branch,_that.number,_that.patientId,_that.invoiceDate,_that.totalMinor,_that.discountMinor,_that.valueMinor,_that.collectedMinor,_that.dueMinor,_that.refundedMinor,_that.status,_that.services,_that.doctors,_that.createdAt,_that.createdByName,_that.version);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  ClinicLocation branch,  int number, @JsonKey(name: 'patient_id')  String patientId, @JsonKey(name: 'invoice_date')  DateTime invoiceDate, @JsonKey(name: 'total_minor')  int totalMinor, @JsonKey(name: 'discount_minor')  int discountMinor, @JsonKey(name: 'value_minor')  int valueMinor, @JsonKey(name: 'net_collected_minor')  int collectedMinor, @JsonKey(name: 'due_minor')  int dueMinor, @JsonKey(name: 'refunded_minor')  int refundedMinor, @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)  InvoiceStatus status,  String services, @JsonKey(fromJson: _doctorsFromJson)  List<String> doctors, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'created_by_name')  String createdByName,  int version)?  $default,) {final _that = this;
switch (_that) {
case _InvoiceSummary() when $default != null:
return $default(_that.id,_that.branch,_that.number,_that.patientId,_that.invoiceDate,_that.totalMinor,_that.discountMinor,_that.valueMinor,_that.collectedMinor,_that.dueMinor,_that.refundedMinor,_that.status,_that.services,_that.doctors,_that.createdAt,_that.createdByName,_that.version);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InvoiceSummary extends InvoiceSummary {
  const _InvoiceSummary({required this.id, required this.branch, required this.number, @JsonKey(name: 'patient_id') required this.patientId, @JsonKey(name: 'invoice_date') required this.invoiceDate, @JsonKey(name: 'total_minor') required this.totalMinor, @JsonKey(name: 'discount_minor') required this.discountMinor, @JsonKey(name: 'value_minor') required this.valueMinor, @JsonKey(name: 'net_collected_minor') required this.collectedMinor, @JsonKey(name: 'due_minor') required this.dueMinor, @JsonKey(name: 'refunded_minor') required this.refundedMinor, @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson) required this.status, this.services = '', @JsonKey(fromJson: _doctorsFromJson) final  List<String> doctors = const [], @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'created_by_name') required this.createdByName, required this.version}): _doctors = doctors,super._();
  factory _InvoiceSummary.fromJson(Map<String, dynamic> json) => _$InvoiceSummaryFromJson(json);

@override final  String id;
@override final  ClinicLocation branch;
@override final  int number;
@override@JsonKey(name: 'patient_id') final  String patientId;
@override@JsonKey(name: 'invoice_date') final  DateTime invoiceDate;
@override@JsonKey(name: 'total_minor') final  int totalMinor;
@override@JsonKey(name: 'discount_minor') final  int discountMinor;
@override@JsonKey(name: 'value_minor') final  int valueMinor;
@override@JsonKey(name: 'net_collected_minor') final  int collectedMinor;
@override@JsonKey(name: 'due_minor') final  int dueMinor;
@override@JsonKey(name: 'refunded_minor') final  int refundedMinor;
@override@JsonKey(fromJson: _statusFromJson, toJson: _statusToJson) final  InvoiceStatus status;
@override@JsonKey() final  String services;
 final  List<String> _doctors;
@override@JsonKey(fromJson: _doctorsFromJson) List<String> get doctors {
  if (_doctors is EqualUnmodifiableListView) return _doctors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_doctors);
}

@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'created_by_name') final  String createdByName;
@override final  int version;

/// Create a copy of InvoiceSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvoiceSummaryCopyWith<_InvoiceSummary> get copyWith => __$InvoiceSummaryCopyWithImpl<_InvoiceSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvoiceSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvoiceSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.branch, branch) || other.branch == branch)&&(identical(other.number, number) || other.number == number)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.invoiceDate, invoiceDate) || other.invoiceDate == invoiceDate)&&(identical(other.totalMinor, totalMinor) || other.totalMinor == totalMinor)&&(identical(other.discountMinor, discountMinor) || other.discountMinor == discountMinor)&&(identical(other.valueMinor, valueMinor) || other.valueMinor == valueMinor)&&(identical(other.collectedMinor, collectedMinor) || other.collectedMinor == collectedMinor)&&(identical(other.dueMinor, dueMinor) || other.dueMinor == dueMinor)&&(identical(other.refundedMinor, refundedMinor) || other.refundedMinor == refundedMinor)&&(identical(other.status, status) || other.status == status)&&(identical(other.services, services) || other.services == services)&&const DeepCollectionEquality().equals(other._doctors, _doctors)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdByName, createdByName) || other.createdByName == createdByName)&&(identical(other.version, version) || other.version == version));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,branch,number,patientId,invoiceDate,totalMinor,discountMinor,valueMinor,collectedMinor,dueMinor,refundedMinor,status,services,const DeepCollectionEquality().hash(_doctors),createdAt,createdByName,version);

@override
String toString() {
  return 'InvoiceSummary(id: $id, branch: $branch, number: $number, patientId: $patientId, invoiceDate: $invoiceDate, totalMinor: $totalMinor, discountMinor: $discountMinor, valueMinor: $valueMinor, collectedMinor: $collectedMinor, dueMinor: $dueMinor, refundedMinor: $refundedMinor, status: $status, services: $services, doctors: $doctors, createdAt: $createdAt, createdByName: $createdByName, version: $version)';
}


}

/// @nodoc
abstract mixin class _$InvoiceSummaryCopyWith<$Res> implements $InvoiceSummaryCopyWith<$Res> {
  factory _$InvoiceSummaryCopyWith(_InvoiceSummary value, $Res Function(_InvoiceSummary) _then) = __$InvoiceSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, ClinicLocation branch, int number,@JsonKey(name: 'patient_id') String patientId,@JsonKey(name: 'invoice_date') DateTime invoiceDate,@JsonKey(name: 'total_minor') int totalMinor,@JsonKey(name: 'discount_minor') int discountMinor,@JsonKey(name: 'value_minor') int valueMinor,@JsonKey(name: 'net_collected_minor') int collectedMinor,@JsonKey(name: 'due_minor') int dueMinor,@JsonKey(name: 'refunded_minor') int refundedMinor,@JsonKey(fromJson: _statusFromJson, toJson: _statusToJson) InvoiceStatus status, String services,@JsonKey(fromJson: _doctorsFromJson) List<String> doctors,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'created_by_name') String createdByName, int version
});




}
/// @nodoc
class __$InvoiceSummaryCopyWithImpl<$Res>
    implements _$InvoiceSummaryCopyWith<$Res> {
  __$InvoiceSummaryCopyWithImpl(this._self, this._then);

  final _InvoiceSummary _self;
  final $Res Function(_InvoiceSummary) _then;

/// Create a copy of InvoiceSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? branch = null,Object? number = null,Object? patientId = null,Object? invoiceDate = null,Object? totalMinor = null,Object? discountMinor = null,Object? valueMinor = null,Object? collectedMinor = null,Object? dueMinor = null,Object? refundedMinor = null,Object? status = null,Object? services = null,Object? doctors = null,Object? createdAt = null,Object? createdByName = null,Object? version = null,}) {
  return _then(_InvoiceSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,branch: null == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as ClinicLocation,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,invoiceDate: null == invoiceDate ? _self.invoiceDate : invoiceDate // ignore: cast_nullable_to_non_nullable
as DateTime,totalMinor: null == totalMinor ? _self.totalMinor : totalMinor // ignore: cast_nullable_to_non_nullable
as int,discountMinor: null == discountMinor ? _self.discountMinor : discountMinor // ignore: cast_nullable_to_non_nullable
as int,valueMinor: null == valueMinor ? _self.valueMinor : valueMinor // ignore: cast_nullable_to_non_nullable
as int,collectedMinor: null == collectedMinor ? _self.collectedMinor : collectedMinor // ignore: cast_nullable_to_non_nullable
as int,dueMinor: null == dueMinor ? _self.dueMinor : dueMinor // ignore: cast_nullable_to_non_nullable
as int,refundedMinor: null == refundedMinor ? _self.refundedMinor : refundedMinor // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InvoiceStatus,services: null == services ? _self.services : services // ignore: cast_nullable_to_non_nullable
as String,doctors: null == doctors ? _self._doctors : doctors // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdByName: null == createdByName ? _self.createdByName : createdByName // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
