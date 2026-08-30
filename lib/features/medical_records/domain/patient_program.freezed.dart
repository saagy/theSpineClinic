// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'patient_program.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PatientProgram {

 String get id;@JsonKey(name: 'patient_id') String get patientId;@JsonKey(name: 'created_by') String get createdBy; ProgramStatus get status; String? get examination;@JsonKey(name: 'imaging_notes') String? get imagingNotes;@JsonKey(name: 'exaggerating_positions') String? get exaggeratingPositions;@JsonKey(name: 'relieving_positions') String? get relievingPositions; String? get notes;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt;@JsonKey(name: 'program_conditions') List<ProgramCondition> get conditions;@JsonKey(name: 'treatment_plans') List<TreatmentPlan> get treatmentPlans;
/// Create a copy of PatientProgram
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PatientProgramCopyWith<PatientProgram> get copyWith => _$PatientProgramCopyWithImpl<PatientProgram>(this as PatientProgram, _$identity);

  /// Serializes this PatientProgram to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PatientProgram&&(identical(other.id, id) || other.id == id)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.status, status) || other.status == status)&&(identical(other.examination, examination) || other.examination == examination)&&(identical(other.imagingNotes, imagingNotes) || other.imagingNotes == imagingNotes)&&(identical(other.exaggeratingPositions, exaggeratingPositions) || other.exaggeratingPositions == exaggeratingPositions)&&(identical(other.relievingPositions, relievingPositions) || other.relievingPositions == relievingPositions)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other.conditions, conditions)&&const DeepCollectionEquality().equals(other.treatmentPlans, treatmentPlans));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,patientId,createdBy,status,examination,imagingNotes,exaggeratingPositions,relievingPositions,notes,createdAt,updatedAt,const DeepCollectionEquality().hash(conditions),const DeepCollectionEquality().hash(treatmentPlans));

@override
String toString() {
  return 'PatientProgram(id: $id, patientId: $patientId, createdBy: $createdBy, status: $status, examination: $examination, imagingNotes: $imagingNotes, exaggeratingPositions: $exaggeratingPositions, relievingPositions: $relievingPositions, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt, conditions: $conditions, treatmentPlans: $treatmentPlans)';
}


}

/// @nodoc
abstract mixin class $PatientProgramCopyWith<$Res>  {
  factory $PatientProgramCopyWith(PatientProgram value, $Res Function(PatientProgram) _then) = _$PatientProgramCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'patient_id') String patientId,@JsonKey(name: 'created_by') String createdBy, ProgramStatus status, String? examination,@JsonKey(name: 'imaging_notes') String? imagingNotes,@JsonKey(name: 'exaggerating_positions') String? exaggeratingPositions,@JsonKey(name: 'relieving_positions') String? relievingPositions, String? notes,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'program_conditions') List<ProgramCondition> conditions,@JsonKey(name: 'treatment_plans') List<TreatmentPlan> treatmentPlans
});




}
/// @nodoc
class _$PatientProgramCopyWithImpl<$Res>
    implements $PatientProgramCopyWith<$Res> {
  _$PatientProgramCopyWithImpl(this._self, this._then);

  final PatientProgram _self;
  final $Res Function(PatientProgram) _then;

/// Create a copy of PatientProgram
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? patientId = null,Object? createdBy = null,Object? status = null,Object? examination = freezed,Object? imagingNotes = freezed,Object? exaggeratingPositions = freezed,Object? relievingPositions = freezed,Object? notes = freezed,Object? createdAt = null,Object? updatedAt = null,Object? conditions = null,Object? treatmentPlans = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ProgramStatus,examination: freezed == examination ? _self.examination : examination // ignore: cast_nullable_to_non_nullable
as String?,imagingNotes: freezed == imagingNotes ? _self.imagingNotes : imagingNotes // ignore: cast_nullable_to_non_nullable
as String?,exaggeratingPositions: freezed == exaggeratingPositions ? _self.exaggeratingPositions : exaggeratingPositions // ignore: cast_nullable_to_non_nullable
as String?,relievingPositions: freezed == relievingPositions ? _self.relievingPositions : relievingPositions // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,conditions: null == conditions ? _self.conditions : conditions // ignore: cast_nullable_to_non_nullable
as List<ProgramCondition>,treatmentPlans: null == treatmentPlans ? _self.treatmentPlans : treatmentPlans // ignore: cast_nullable_to_non_nullable
as List<TreatmentPlan>,
  ));
}

}


/// Adds pattern-matching-related methods to [PatientProgram].
extension PatientProgramPatterns on PatientProgram {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PatientProgram value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PatientProgram() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PatientProgram value)  $default,){
final _that = this;
switch (_that) {
case _PatientProgram():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PatientProgram value)?  $default,){
final _that = this;
switch (_that) {
case _PatientProgram() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'patient_id')  String patientId, @JsonKey(name: 'created_by')  String createdBy,  ProgramStatus status,  String? examination, @JsonKey(name: 'imaging_notes')  String? imagingNotes, @JsonKey(name: 'exaggerating_positions')  String? exaggeratingPositions, @JsonKey(name: 'relieving_positions')  String? relievingPositions,  String? notes, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'program_conditions')  List<ProgramCondition> conditions, @JsonKey(name: 'treatment_plans')  List<TreatmentPlan> treatmentPlans)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PatientProgram() when $default != null:
return $default(_that.id,_that.patientId,_that.createdBy,_that.status,_that.examination,_that.imagingNotes,_that.exaggeratingPositions,_that.relievingPositions,_that.notes,_that.createdAt,_that.updatedAt,_that.conditions,_that.treatmentPlans);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'patient_id')  String patientId, @JsonKey(name: 'created_by')  String createdBy,  ProgramStatus status,  String? examination, @JsonKey(name: 'imaging_notes')  String? imagingNotes, @JsonKey(name: 'exaggerating_positions')  String? exaggeratingPositions, @JsonKey(name: 'relieving_positions')  String? relievingPositions,  String? notes, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'program_conditions')  List<ProgramCondition> conditions, @JsonKey(name: 'treatment_plans')  List<TreatmentPlan> treatmentPlans)  $default,) {final _that = this;
switch (_that) {
case _PatientProgram():
return $default(_that.id,_that.patientId,_that.createdBy,_that.status,_that.examination,_that.imagingNotes,_that.exaggeratingPositions,_that.relievingPositions,_that.notes,_that.createdAt,_that.updatedAt,_that.conditions,_that.treatmentPlans);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'patient_id')  String patientId, @JsonKey(name: 'created_by')  String createdBy,  ProgramStatus status,  String? examination, @JsonKey(name: 'imaging_notes')  String? imagingNotes, @JsonKey(name: 'exaggerating_positions')  String? exaggeratingPositions, @JsonKey(name: 'relieving_positions')  String? relievingPositions,  String? notes, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'program_conditions')  List<ProgramCondition> conditions, @JsonKey(name: 'treatment_plans')  List<TreatmentPlan> treatmentPlans)?  $default,) {final _that = this;
switch (_that) {
case _PatientProgram() when $default != null:
return $default(_that.id,_that.patientId,_that.createdBy,_that.status,_that.examination,_that.imagingNotes,_that.exaggeratingPositions,_that.relievingPositions,_that.notes,_that.createdAt,_that.updatedAt,_that.conditions,_that.treatmentPlans);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PatientProgram extends PatientProgram {
  const _PatientProgram({required this.id, @JsonKey(name: 'patient_id') required this.patientId, @JsonKey(name: 'created_by') required this.createdBy, this.status = ProgramStatus.active, this.examination, @JsonKey(name: 'imaging_notes') this.imagingNotes, @JsonKey(name: 'exaggerating_positions') this.exaggeratingPositions, @JsonKey(name: 'relieving_positions') this.relievingPositions, this.notes, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt, @JsonKey(name: 'program_conditions') final  List<ProgramCondition> conditions = const [], @JsonKey(name: 'treatment_plans') final  List<TreatmentPlan> treatmentPlans = const []}): _conditions = conditions,_treatmentPlans = treatmentPlans,super._();
  factory _PatientProgram.fromJson(Map<String, dynamic> json) => _$PatientProgramFromJson(json);

@override final  String id;
@override@JsonKey(name: 'patient_id') final  String patientId;
@override@JsonKey(name: 'created_by') final  String createdBy;
@override@JsonKey() final  ProgramStatus status;
@override final  String? examination;
@override@JsonKey(name: 'imaging_notes') final  String? imagingNotes;
@override@JsonKey(name: 'exaggerating_positions') final  String? exaggeratingPositions;
@override@JsonKey(name: 'relieving_positions') final  String? relievingPositions;
@override final  String? notes;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;
 final  List<ProgramCondition> _conditions;
@override@JsonKey(name: 'program_conditions') List<ProgramCondition> get conditions {
  if (_conditions is EqualUnmodifiableListView) return _conditions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_conditions);
}

 final  List<TreatmentPlan> _treatmentPlans;
@override@JsonKey(name: 'treatment_plans') List<TreatmentPlan> get treatmentPlans {
  if (_treatmentPlans is EqualUnmodifiableListView) return _treatmentPlans;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_treatmentPlans);
}


/// Create a copy of PatientProgram
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PatientProgramCopyWith<_PatientProgram> get copyWith => __$PatientProgramCopyWithImpl<_PatientProgram>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PatientProgramToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PatientProgram&&(identical(other.id, id) || other.id == id)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.status, status) || other.status == status)&&(identical(other.examination, examination) || other.examination == examination)&&(identical(other.imagingNotes, imagingNotes) || other.imagingNotes == imagingNotes)&&(identical(other.exaggeratingPositions, exaggeratingPositions) || other.exaggeratingPositions == exaggeratingPositions)&&(identical(other.relievingPositions, relievingPositions) || other.relievingPositions == relievingPositions)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other._conditions, _conditions)&&const DeepCollectionEquality().equals(other._treatmentPlans, _treatmentPlans));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,patientId,createdBy,status,examination,imagingNotes,exaggeratingPositions,relievingPositions,notes,createdAt,updatedAt,const DeepCollectionEquality().hash(_conditions),const DeepCollectionEquality().hash(_treatmentPlans));

@override
String toString() {
  return 'PatientProgram(id: $id, patientId: $patientId, createdBy: $createdBy, status: $status, examination: $examination, imagingNotes: $imagingNotes, exaggeratingPositions: $exaggeratingPositions, relievingPositions: $relievingPositions, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt, conditions: $conditions, treatmentPlans: $treatmentPlans)';
}


}

/// @nodoc
abstract mixin class _$PatientProgramCopyWith<$Res> implements $PatientProgramCopyWith<$Res> {
  factory _$PatientProgramCopyWith(_PatientProgram value, $Res Function(_PatientProgram) _then) = __$PatientProgramCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'patient_id') String patientId,@JsonKey(name: 'created_by') String createdBy, ProgramStatus status, String? examination,@JsonKey(name: 'imaging_notes') String? imagingNotes,@JsonKey(name: 'exaggerating_positions') String? exaggeratingPositions,@JsonKey(name: 'relieving_positions') String? relievingPositions, String? notes,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'program_conditions') List<ProgramCondition> conditions,@JsonKey(name: 'treatment_plans') List<TreatmentPlan> treatmentPlans
});




}
/// @nodoc
class __$PatientProgramCopyWithImpl<$Res>
    implements _$PatientProgramCopyWith<$Res> {
  __$PatientProgramCopyWithImpl(this._self, this._then);

  final _PatientProgram _self;
  final $Res Function(_PatientProgram) _then;

/// Create a copy of PatientProgram
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? patientId = null,Object? createdBy = null,Object? status = null,Object? examination = freezed,Object? imagingNotes = freezed,Object? exaggeratingPositions = freezed,Object? relievingPositions = freezed,Object? notes = freezed,Object? createdAt = null,Object? updatedAt = null,Object? conditions = null,Object? treatmentPlans = null,}) {
  return _then(_PatientProgram(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ProgramStatus,examination: freezed == examination ? _self.examination : examination // ignore: cast_nullable_to_non_nullable
as String?,imagingNotes: freezed == imagingNotes ? _self.imagingNotes : imagingNotes // ignore: cast_nullable_to_non_nullable
as String?,exaggeratingPositions: freezed == exaggeratingPositions ? _self.exaggeratingPositions : exaggeratingPositions // ignore: cast_nullable_to_non_nullable
as String?,relievingPositions: freezed == relievingPositions ? _self.relievingPositions : relievingPositions // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,conditions: null == conditions ? _self._conditions : conditions // ignore: cast_nullable_to_non_nullable
as List<ProgramCondition>,treatmentPlans: null == treatmentPlans ? _self._treatmentPlans : treatmentPlans // ignore: cast_nullable_to_non_nullable
as List<TreatmentPlan>,
  ));
}


}

// dart format on
