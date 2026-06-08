// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'patient_document.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PatientDocument {

/// Primary key (`uuid`).
 String get id;/// FK referencing patients(id).
@JsonKey(name: 'patient_id') String get patientId;/// Publicly accessible Supabase Storage URL.
@JsonKey(name: 'file_url') String get fileUrl;/// Raw name of the file (e.g. 'xray.pdf').
@JsonKey(name: 'file_name') String get fileName;/// FK referencing staff(id) who uploaded it — nullable.
@JsonKey(name: 'uploaded_by') String? get uploadedBy;/// Row creation/upload timestamp.
@JsonKey(name: 'uploaded_at') DateTime get uploadedAt;
/// Create a copy of PatientDocument
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PatientDocumentCopyWith<PatientDocument> get copyWith => _$PatientDocumentCopyWithImpl<PatientDocument>(this as PatientDocument, _$identity);

  /// Serializes this PatientDocument to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PatientDocument&&(identical(other.id, id) || other.id == id)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.uploadedBy, uploadedBy) || other.uploadedBy == uploadedBy)&&(identical(other.uploadedAt, uploadedAt) || other.uploadedAt == uploadedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,patientId,fileUrl,fileName,uploadedBy,uploadedAt);

@override
String toString() {
  return 'PatientDocument(id: $id, patientId: $patientId, fileUrl: $fileUrl, fileName: $fileName, uploadedBy: $uploadedBy, uploadedAt: $uploadedAt)';
}


}

/// @nodoc
abstract mixin class $PatientDocumentCopyWith<$Res>  {
  factory $PatientDocumentCopyWith(PatientDocument value, $Res Function(PatientDocument) _then) = _$PatientDocumentCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'patient_id') String patientId,@JsonKey(name: 'file_url') String fileUrl,@JsonKey(name: 'file_name') String fileName,@JsonKey(name: 'uploaded_by') String? uploadedBy,@JsonKey(name: 'uploaded_at') DateTime uploadedAt
});




}
/// @nodoc
class _$PatientDocumentCopyWithImpl<$Res>
    implements $PatientDocumentCopyWith<$Res> {
  _$PatientDocumentCopyWithImpl(this._self, this._then);

  final PatientDocument _self;
  final $Res Function(PatientDocument) _then;

/// Create a copy of PatientDocument
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? patientId = null,Object? fileUrl = null,Object? fileName = null,Object? uploadedBy = freezed,Object? uploadedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,fileUrl: null == fileUrl ? _self.fileUrl : fileUrl // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,uploadedBy: freezed == uploadedBy ? _self.uploadedBy : uploadedBy // ignore: cast_nullable_to_non_nullable
as String?,uploadedAt: null == uploadedAt ? _self.uploadedAt : uploadedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [PatientDocument].
extension PatientDocumentPatterns on PatientDocument {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PatientDocument value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PatientDocument() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PatientDocument value)  $default,){
final _that = this;
switch (_that) {
case _PatientDocument():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PatientDocument value)?  $default,){
final _that = this;
switch (_that) {
case _PatientDocument() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'patient_id')  String patientId, @JsonKey(name: 'file_url')  String fileUrl, @JsonKey(name: 'file_name')  String fileName, @JsonKey(name: 'uploaded_by')  String? uploadedBy, @JsonKey(name: 'uploaded_at')  DateTime uploadedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PatientDocument() when $default != null:
return $default(_that.id,_that.patientId,_that.fileUrl,_that.fileName,_that.uploadedBy,_that.uploadedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'patient_id')  String patientId, @JsonKey(name: 'file_url')  String fileUrl, @JsonKey(name: 'file_name')  String fileName, @JsonKey(name: 'uploaded_by')  String? uploadedBy, @JsonKey(name: 'uploaded_at')  DateTime uploadedAt)  $default,) {final _that = this;
switch (_that) {
case _PatientDocument():
return $default(_that.id,_that.patientId,_that.fileUrl,_that.fileName,_that.uploadedBy,_that.uploadedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'patient_id')  String patientId, @JsonKey(name: 'file_url')  String fileUrl, @JsonKey(name: 'file_name')  String fileName, @JsonKey(name: 'uploaded_by')  String? uploadedBy, @JsonKey(name: 'uploaded_at')  DateTime uploadedAt)?  $default,) {final _that = this;
switch (_that) {
case _PatientDocument() when $default != null:
return $default(_that.id,_that.patientId,_that.fileUrl,_that.fileName,_that.uploadedBy,_that.uploadedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PatientDocument implements PatientDocument {
  const _PatientDocument({required this.id, @JsonKey(name: 'patient_id') required this.patientId, @JsonKey(name: 'file_url') required this.fileUrl, @JsonKey(name: 'file_name') required this.fileName, @JsonKey(name: 'uploaded_by') this.uploadedBy, @JsonKey(name: 'uploaded_at') required this.uploadedAt});
  factory _PatientDocument.fromJson(Map<String, dynamic> json) => _$PatientDocumentFromJson(json);

/// Primary key (`uuid`).
@override final  String id;
/// FK referencing patients(id).
@override@JsonKey(name: 'patient_id') final  String patientId;
/// Publicly accessible Supabase Storage URL.
@override@JsonKey(name: 'file_url') final  String fileUrl;
/// Raw name of the file (e.g. 'xray.pdf').
@override@JsonKey(name: 'file_name') final  String fileName;
/// FK referencing staff(id) who uploaded it — nullable.
@override@JsonKey(name: 'uploaded_by') final  String? uploadedBy;
/// Row creation/upload timestamp.
@override@JsonKey(name: 'uploaded_at') final  DateTime uploadedAt;

/// Create a copy of PatientDocument
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PatientDocumentCopyWith<_PatientDocument> get copyWith => __$PatientDocumentCopyWithImpl<_PatientDocument>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PatientDocumentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PatientDocument&&(identical(other.id, id) || other.id == id)&&(identical(other.patientId, patientId) || other.patientId == patientId)&&(identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.uploadedBy, uploadedBy) || other.uploadedBy == uploadedBy)&&(identical(other.uploadedAt, uploadedAt) || other.uploadedAt == uploadedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,patientId,fileUrl,fileName,uploadedBy,uploadedAt);

@override
String toString() {
  return 'PatientDocument(id: $id, patientId: $patientId, fileUrl: $fileUrl, fileName: $fileName, uploadedBy: $uploadedBy, uploadedAt: $uploadedAt)';
}


}

/// @nodoc
abstract mixin class _$PatientDocumentCopyWith<$Res> implements $PatientDocumentCopyWith<$Res> {
  factory _$PatientDocumentCopyWith(_PatientDocument value, $Res Function(_PatientDocument) _then) = __$PatientDocumentCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'patient_id') String patientId,@JsonKey(name: 'file_url') String fileUrl,@JsonKey(name: 'file_name') String fileName,@JsonKey(name: 'uploaded_by') String? uploadedBy,@JsonKey(name: 'uploaded_at') DateTime uploadedAt
});




}
/// @nodoc
class __$PatientDocumentCopyWithImpl<$Res>
    implements _$PatientDocumentCopyWith<$Res> {
  __$PatientDocumentCopyWithImpl(this._self, this._then);

  final _PatientDocument _self;
  final $Res Function(_PatientDocument) _then;

/// Create a copy of PatientDocument
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? patientId = null,Object? fileUrl = null,Object? fileName = null,Object? uploadedBy = freezed,Object? uploadedAt = null,}) {
  return _then(_PatientDocument(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patientId: null == patientId ? _self.patientId : patientId // ignore: cast_nullable_to_non_nullable
as String,fileUrl: null == fileUrl ? _self.fileUrl : fileUrl // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,uploadedBy: freezed == uploadedBy ? _self.uploadedBy : uploadedBy // ignore: cast_nullable_to_non_nullable
as String?,uploadedAt: null == uploadedAt ? _self.uploadedAt : uploadedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
