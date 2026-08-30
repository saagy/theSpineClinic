// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'patient_medical_history.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PatientMedicalHistory {

 String get id;@JsonKey(name: 'patient_id') String get patientId;@JsonKey(name: 'has_diabetes') bool get hasDiabetes;@JsonKey(name: 'hba1c_value') String? get hba1cValue;@JsonKey(name: 'has_hypertension') bool get hasHypertension;@JsonKey(name: 'has_hyperlipidemia') bool get hasHyperlipidemia;@JsonKey(name: 'has_rheumatology') bool get hasRheumatology;@JsonKey(name: 'rheumatology_details') String? get rheumatologyDetails;@JsonKey(name: 'additional_notes') String? get additionalNotes;@JsonKey(name: 'updated_by') String? get updatedBy;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt;
/// Create a copy of PatientMedicalHistory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PatientMedicalHistoryCopyWith<PatientMedicalHistory> get copyWith => _$PatientMedicalHistoryCopyWithImpl<PatientMedicalHistory>(this as PatientMedicalHistory, _$identity);

  /// Serializes this PatientMedicalHistory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PatientMedicalHistory&&(identical(other.id, id) || other.id == id)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.hasDiabetes, hasDiabetes) || other.hasDiabetes == hasDiabetes)&&(identical(other.hba1cValue, hba1cValue) || other.hba1cValue == hba1cValue)&&(identical(other.hasHypertension, hasHypertension) || other.hasHypertension == hasHypertension)&&(identical(other.hasHyperlipidemia, hasHyperlipidemia) || other.hasHyperlipidemia == hasHyperlipidemia)&&(identical(other.hasRheumatology, hasRheumatology) || other.hasRheumatology == hasRheumatology)&&(identical(other.rheumatologyDetails, rheumatologyDetails) || other.rheumatologyDetails == rheumatologyDetails)&&(identical(other.additionalNotes, additionalNotes) || other.additionalNotes == additionalNotes)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,patientId,hasDiabetes,hba1cValue,hasHypertension,hasHyperlipidemia,hasRheumatology,rheumatologyDetails,additionalNotes,updatedBy,createdAt,updatedAt);

@override
String toString() {
  return 'PatientMedicalHistory(id: $id, patientId: $patientId, hasDiabetes: $hasDiabetes, hba1cValue: $hba1cValue, hasHypertension: $hasHypertension, hasHyperlipidemia: $hasHyperlipidemia, hasRheumatology: $hasRheumatology, rheumatologyDetails: $rheumatologyDetails, additionalNotes: $additionalNotes, updatedBy: $updatedBy, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $PatientMedicalHistoryCopyWith<$Res>  {
  factory $PatientMedicalHistoryCopyWith(PatientMedicalHistory value, $Res Function(PatientMedicalHistory) _then) = _$PatientMedicalHistoryCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'patient_id') String patientId,@JsonKey(name: 'has_diabetes') bool hasDiabetes,@JsonKey(name: 'hba1c_value') String? hba1cValue,@JsonKey(name: 'has_hypertension') bool hasHypertension,@JsonKey(name: 'has_hyperlipidemia') bool hasHyperlipidemia,@JsonKey(name: 'has_rheumatology') bool hasRheumatology,@JsonKey(name: 'rheumatology_details') String? rheumatologyDetails,@JsonKey(name: 'additional_notes') String? additionalNotes,@JsonKey(name: 'updated_by') String? updatedBy,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt
});




}
/// @nodoc
class _$PatientMedicalHistoryCopyWithImpl<$Res>
    implements $PatientMedicalHistoryCopyWith<$Res> {
  _$PatientMedicalHistoryCopyWithImpl(this._self, this._then);

  final PatientMedicalHistory _self;
  final $Res Function(PatientMedicalHistory) _then;

/// Create a copy of PatientMedicalHistory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? patientId = null,Object? hasDiabetes = null,Object? hba1cValue = freezed,Object? hasHypertension = null,Object? hasHyperlipidemia = null,Object? hasRheumatology = null,Object? rheumatologyDetails = freezed,Object? additionalNotes = freezed,Object? updatedBy = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,hasDiabetes: null == hasDiabetes ? _self.hasDiabetes : hasDiabetes // ignore: cast_nullable_to_non_nullable
as bool,hba1cValue: freezed == hba1cValue ? _self.hba1cValue : hba1cValue // ignore: cast_nullable_to_non_nullable
as String?,hasHypertension: null == hasHypertension ? _self.hasHypertension : hasHypertension // ignore: cast_nullable_to_non_nullable
as bool,hasHyperlipidemia: null == hasHyperlipidemia ? _self.hasHyperlipidemia : hasHyperlipidemia // ignore: cast_nullable_to_non_nullable
as bool,hasRheumatology: null == hasRheumatology ? _self.hasRheumatology : hasRheumatology // ignore: cast_nullable_to_non_nullable
as bool,rheumatologyDetails: freezed == rheumatologyDetails ? _self.rheumatologyDetails : rheumatologyDetails // ignore: cast_nullable_to_non_nullable
as String?,additionalNotes: freezed == additionalNotes ? _self.additionalNotes : additionalNotes // ignore: cast_nullable_to_non_nullable
as String?,updatedBy: freezed == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [PatientMedicalHistory].
extension PatientMedicalHistoryPatterns on PatientMedicalHistory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PatientMedicalHistory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PatientMedicalHistory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PatientMedicalHistory value)  $default,){
final _that = this;
switch (_that) {
case _PatientMedicalHistory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PatientMedicalHistory value)?  $default,){
final _that = this;
switch (_that) {
case _PatientMedicalHistory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'patient_id')  String patientId, @JsonKey(name: 'has_diabetes')  bool hasDiabetes, @JsonKey(name: 'hba1c_value')  String? hba1cValue, @JsonKey(name: 'has_hypertension')  bool hasHypertension, @JsonKey(name: 'has_hyperlipidemia')  bool hasHyperlipidemia, @JsonKey(name: 'has_rheumatology')  bool hasRheumatology, @JsonKey(name: 'rheumatology_details')  String? rheumatologyDetails, @JsonKey(name: 'additional_notes')  String? additionalNotes, @JsonKey(name: 'updated_by')  String? updatedBy, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PatientMedicalHistory() when $default != null:
return $default(_that.id,_that.patientId,_that.hasDiabetes,_that.hba1cValue,_that.hasHypertension,_that.hasHyperlipidemia,_that.hasRheumatology,_that.rheumatologyDetails,_that.additionalNotes,_that.updatedBy,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'patient_id')  String patientId, @JsonKey(name: 'has_diabetes')  bool hasDiabetes, @JsonKey(name: 'hba1c_value')  String? hba1cValue, @JsonKey(name: 'has_hypertension')  bool hasHypertension, @JsonKey(name: 'has_hyperlipidemia')  bool hasHyperlipidemia, @JsonKey(name: 'has_rheumatology')  bool hasRheumatology, @JsonKey(name: 'rheumatology_details')  String? rheumatologyDetails, @JsonKey(name: 'additional_notes')  String? additionalNotes, @JsonKey(name: 'updated_by')  String? updatedBy, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _PatientMedicalHistory():
return $default(_that.id,_that.patientId,_that.hasDiabetes,_that.hba1cValue,_that.hasHypertension,_that.hasHyperlipidemia,_that.hasRheumatology,_that.rheumatologyDetails,_that.additionalNotes,_that.updatedBy,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'patient_id')  String patientId, @JsonKey(name: 'has_diabetes')  bool hasDiabetes, @JsonKey(name: 'hba1c_value')  String? hba1cValue, @JsonKey(name: 'has_hypertension')  bool hasHypertension, @JsonKey(name: 'has_hyperlipidemia')  bool hasHyperlipidemia, @JsonKey(name: 'has_rheumatology')  bool hasRheumatology, @JsonKey(name: 'rheumatology_details')  String? rheumatologyDetails, @JsonKey(name: 'additional_notes')  String? additionalNotes, @JsonKey(name: 'updated_by')  String? updatedBy, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _PatientMedicalHistory() when $default != null:
return $default(_that.id,_that.patientId,_that.hasDiabetes,_that.hba1cValue,_that.hasHypertension,_that.hasHyperlipidemia,_that.hasRheumatology,_that.rheumatologyDetails,_that.additionalNotes,_that.updatedBy,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PatientMedicalHistory extends PatientMedicalHistory {
  const _PatientMedicalHistory({required this.id, @JsonKey(name: 'patient_id') required this.patientId, @JsonKey(name: 'has_diabetes') this.hasDiabetes = false, @JsonKey(name: 'hba1c_value') this.hba1cValue, @JsonKey(name: 'has_hypertension') this.hasHypertension = false, @JsonKey(name: 'has_hyperlipidemia') this.hasHyperlipidemia = false, @JsonKey(name: 'has_rheumatology') this.hasRheumatology = false, @JsonKey(name: 'rheumatology_details') this.rheumatologyDetails, @JsonKey(name: 'additional_notes') this.additionalNotes, @JsonKey(name: 'updated_by') this.updatedBy, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt}): super._();
  factory _PatientMedicalHistory.fromJson(Map<String, dynamic> json) => _$PatientMedicalHistoryFromJson(json);

@override final  String id;
@override@JsonKey(name: 'patient_id') final  String patientId;
@override@JsonKey(name: 'has_diabetes') final  bool hasDiabetes;
@override@JsonKey(name: 'hba1c_value') final  String? hba1cValue;
@override@JsonKey(name: 'has_hypertension') final  bool hasHypertension;
@override@JsonKey(name: 'has_hyperlipidemia') final  bool hasHyperlipidemia;
@override@JsonKey(name: 'has_rheumatology') final  bool hasRheumatology;
@override@JsonKey(name: 'rheumatology_details') final  String? rheumatologyDetails;
@override@JsonKey(name: 'additional_notes') final  String? additionalNotes;
@override@JsonKey(name: 'updated_by') final  String? updatedBy;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;

/// Create a copy of PatientMedicalHistory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PatientMedicalHistoryCopyWith<_PatientMedicalHistory> get copyWith => __$PatientMedicalHistoryCopyWithImpl<_PatientMedicalHistory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PatientMedicalHistoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PatientMedicalHistory&&(identical(other.id, id) || other.id == id)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.hasDiabetes, hasDiabetes) || other.hasDiabetes == hasDiabetes)&&(identical(other.hba1cValue, hba1cValue) || other.hba1cValue == hba1cValue)&&(identical(other.hasHypertension, hasHypertension) || other.hasHypertension == hasHypertension)&&(identical(other.hasHyperlipidemia, hasHyperlipidemia) || other.hasHyperlipidemia == hasHyperlipidemia)&&(identical(other.hasRheumatology, hasRheumatology) || other.hasRheumatology == hasRheumatology)&&(identical(other.rheumatologyDetails, rheumatologyDetails) || other.rheumatologyDetails == rheumatologyDetails)&&(identical(other.additionalNotes, additionalNotes) || other.additionalNotes == additionalNotes)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,patientId,hasDiabetes,hba1cValue,hasHypertension,hasHyperlipidemia,hasRheumatology,rheumatologyDetails,additionalNotes,updatedBy,createdAt,updatedAt);

@override
String toString() {
  return 'PatientMedicalHistory(id: $id, patientId: $patientId, hasDiabetes: $hasDiabetes, hba1cValue: $hba1cValue, hasHypertension: $hasHypertension, hasHyperlipidemia: $hasHyperlipidemia, hasRheumatology: $hasRheumatology, rheumatologyDetails: $rheumatologyDetails, additionalNotes: $additionalNotes, updatedBy: $updatedBy, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PatientMedicalHistoryCopyWith<$Res> implements $PatientMedicalHistoryCopyWith<$Res> {
  factory _$PatientMedicalHistoryCopyWith(_PatientMedicalHistory value, $Res Function(_PatientMedicalHistory) _then) = __$PatientMedicalHistoryCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'patient_id') String patientId,@JsonKey(name: 'has_diabetes') bool hasDiabetes,@JsonKey(name: 'hba1c_value') String? hba1cValue,@JsonKey(name: 'has_hypertension') bool hasHypertension,@JsonKey(name: 'has_hyperlipidemia') bool hasHyperlipidemia,@JsonKey(name: 'has_rheumatology') bool hasRheumatology,@JsonKey(name: 'rheumatology_details') String? rheumatologyDetails,@JsonKey(name: 'additional_notes') String? additionalNotes,@JsonKey(name: 'updated_by') String? updatedBy,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt
});




}
/// @nodoc
class __$PatientMedicalHistoryCopyWithImpl<$Res>
    implements _$PatientMedicalHistoryCopyWith<$Res> {
  __$PatientMedicalHistoryCopyWithImpl(this._self, this._then);

  final _PatientMedicalHistory _self;
  final $Res Function(_PatientMedicalHistory) _then;

/// Create a copy of PatientMedicalHistory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? patientId = null,Object? hasDiabetes = null,Object? hba1cValue = freezed,Object? hasHypertension = null,Object? hasHyperlipidemia = null,Object? hasRheumatology = null,Object? rheumatologyDetails = freezed,Object? additionalNotes = freezed,Object? updatedBy = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_PatientMedicalHistory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,hasDiabetes: null == hasDiabetes ? _self.hasDiabetes : hasDiabetes // ignore: cast_nullable_to_non_nullable
as bool,hba1cValue: freezed == hba1cValue ? _self.hba1cValue : hba1cValue // ignore: cast_nullable_to_non_nullable
as String?,hasHypertension: null == hasHypertension ? _self.hasHypertension : hasHypertension // ignore: cast_nullable_to_non_nullable
as bool,hasHyperlipidemia: null == hasHyperlipidemia ? _self.hasHyperlipidemia : hasHyperlipidemia // ignore: cast_nullable_to_non_nullable
as bool,hasRheumatology: null == hasRheumatology ? _self.hasRheumatology : hasRheumatology // ignore: cast_nullable_to_non_nullable
as bool,rheumatologyDetails: freezed == rheumatologyDetails ? _self.rheumatologyDetails : rheumatologyDetails // ignore: cast_nullable_to_non_nullable
as String?,additionalNotes: freezed == additionalNotes ? _self.additionalNotes : additionalNotes // ignore: cast_nullable_to_non_nullable
as String?,updatedBy: freezed == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
