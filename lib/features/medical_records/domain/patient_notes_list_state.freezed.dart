// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'patient_notes_list_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PatientNotesListState {

 List<PatientNote> get notes; bool get isLoading; bool get isLoadingMore; bool get hasMore; int get totalCount; String? get errorMessage; DateTime? get dateFrom; DateTime? get dateTo; PatientNotesSortOption get sort;
/// Create a copy of PatientNotesListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PatientNotesListStateCopyWith<PatientNotesListState> get copyWith => _$PatientNotesListStateCopyWithImpl<PatientNotesListState>(this as PatientNotesListState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PatientNotesListState&&const DeepCollectionEquality().equals(other.notes, notes)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.dateFrom, dateFrom) || other.dateFrom == dateFrom)&&(identical(other.dateTo, dateTo) || other.dateTo == dateTo)&&(identical(other.sort, sort) || other.sort == sort));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(notes),isLoading,isLoadingMore,hasMore,totalCount,errorMessage,dateFrom,dateTo,sort);

@override
String toString() {
  return 'PatientNotesListState(notes: $notes, isLoading: $isLoading, isLoadingMore: $isLoadingMore, hasMore: $hasMore, totalCount: $totalCount, errorMessage: $errorMessage, dateFrom: $dateFrom, dateTo: $dateTo, sort: $sort)';
}


}

/// @nodoc
abstract mixin class $PatientNotesListStateCopyWith<$Res>  {
  factory $PatientNotesListStateCopyWith(PatientNotesListState value, $Res Function(PatientNotesListState) _then) = _$PatientNotesListStateCopyWithImpl;
@useResult
$Res call({
 List<PatientNote> notes, bool isLoading, bool isLoadingMore, bool hasMore, int totalCount, String? errorMessage, DateTime? dateFrom, DateTime? dateTo, PatientNotesSortOption sort
});




}
/// @nodoc
class _$PatientNotesListStateCopyWithImpl<$Res>
    implements $PatientNotesListStateCopyWith<$Res> {
  _$PatientNotesListStateCopyWithImpl(this._self, this._then);

  final PatientNotesListState _self;
  final $Res Function(PatientNotesListState) _then;

/// Create a copy of PatientNotesListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? notes = null,Object? isLoading = null,Object? isLoadingMore = null,Object? hasMore = null,Object? totalCount = null,Object? errorMessage = freezed,Object? dateFrom = freezed,Object? dateTo = freezed,Object? sort = null,}) {
  return _then(_self.copyWith(
notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as List<PatientNote>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,dateFrom: freezed == dateFrom ? _self.dateFrom : dateFrom // ignore: cast_nullable_to_non_nullable
as DateTime?,dateTo: freezed == dateTo ? _self.dateTo : dateTo // ignore: cast_nullable_to_non_nullable
as DateTime?,sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as PatientNotesSortOption,
  ));
}

}


/// Adds pattern-matching-related methods to [PatientNotesListState].
extension PatientNotesListStatePatterns on PatientNotesListState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PatientNotesListState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PatientNotesListState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PatientNotesListState value)  $default,){
final _that = this;
switch (_that) {
case _PatientNotesListState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PatientNotesListState value)?  $default,){
final _that = this;
switch (_that) {
case _PatientNotesListState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PatientNote> notes,  bool isLoading,  bool isLoadingMore,  bool hasMore,  int totalCount,  String? errorMessage,  DateTime? dateFrom,  DateTime? dateTo,  PatientNotesSortOption sort)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PatientNotesListState() when $default != null:
return $default(_that.notes,_that.isLoading,_that.isLoadingMore,_that.hasMore,_that.totalCount,_that.errorMessage,_that.dateFrom,_that.dateTo,_that.sort);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PatientNote> notes,  bool isLoading,  bool isLoadingMore,  bool hasMore,  int totalCount,  String? errorMessage,  DateTime? dateFrom,  DateTime? dateTo,  PatientNotesSortOption sort)  $default,) {final _that = this;
switch (_that) {
case _PatientNotesListState():
return $default(_that.notes,_that.isLoading,_that.isLoadingMore,_that.hasMore,_that.totalCount,_that.errorMessage,_that.dateFrom,_that.dateTo,_that.sort);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PatientNote> notes,  bool isLoading,  bool isLoadingMore,  bool hasMore,  int totalCount,  String? errorMessage,  DateTime? dateFrom,  DateTime? dateTo,  PatientNotesSortOption sort)?  $default,) {final _that = this;
switch (_that) {
case _PatientNotesListState() when $default != null:
return $default(_that.notes,_that.isLoading,_that.isLoadingMore,_that.hasMore,_that.totalCount,_that.errorMessage,_that.dateFrom,_that.dateTo,_that.sort);case _:
  return null;

}
}

}

/// @nodoc


class _PatientNotesListState implements PatientNotesListState {
  const _PatientNotesListState({final  List<PatientNote> notes = const [], this.isLoading = true, this.isLoadingMore = false, this.hasMore = false, this.totalCount = 0, this.errorMessage, this.dateFrom, this.dateTo, this.sort = PatientNotesSortOption.dateNewest}): _notes = notes;
  

 final  List<PatientNote> _notes;
@override@JsonKey() List<PatientNote> get notes {
  if (_notes is EqualUnmodifiableListView) return _notes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_notes);
}

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isLoadingMore;
@override@JsonKey() final  bool hasMore;
@override@JsonKey() final  int totalCount;
@override final  String? errorMessage;
@override final  DateTime? dateFrom;
@override final  DateTime? dateTo;
@override@JsonKey() final  PatientNotesSortOption sort;

/// Create a copy of PatientNotesListState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PatientNotesListStateCopyWith<_PatientNotesListState> get copyWith => __$PatientNotesListStateCopyWithImpl<_PatientNotesListState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PatientNotesListState&&const DeepCollectionEquality().equals(other._notes, _notes)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.dateFrom, dateFrom) || other.dateFrom == dateFrom)&&(identical(other.dateTo, dateTo) || other.dateTo == dateTo)&&(identical(other.sort, sort) || other.sort == sort));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_notes),isLoading,isLoadingMore,hasMore,totalCount,errorMessage,dateFrom,dateTo,sort);

@override
String toString() {
  return 'PatientNotesListState(notes: $notes, isLoading: $isLoading, isLoadingMore: $isLoadingMore, hasMore: $hasMore, totalCount: $totalCount, errorMessage: $errorMessage, dateFrom: $dateFrom, dateTo: $dateTo, sort: $sort)';
}


}

/// @nodoc
abstract mixin class _$PatientNotesListStateCopyWith<$Res> implements $PatientNotesListStateCopyWith<$Res> {
  factory _$PatientNotesListStateCopyWith(_PatientNotesListState value, $Res Function(_PatientNotesListState) _then) = __$PatientNotesListStateCopyWithImpl;
@override @useResult
$Res call({
 List<PatientNote> notes, bool isLoading, bool isLoadingMore, bool hasMore, int totalCount, String? errorMessage, DateTime? dateFrom, DateTime? dateTo, PatientNotesSortOption sort
});




}
/// @nodoc
class __$PatientNotesListStateCopyWithImpl<$Res>
    implements _$PatientNotesListStateCopyWith<$Res> {
  __$PatientNotesListStateCopyWithImpl(this._self, this._then);

  final _PatientNotesListState _self;
  final $Res Function(_PatientNotesListState) _then;

/// Create a copy of PatientNotesListState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? notes = null,Object? isLoading = null,Object? isLoadingMore = null,Object? hasMore = null,Object? totalCount = null,Object? errorMessage = freezed,Object? dateFrom = freezed,Object? dateTo = freezed,Object? sort = null,}) {
  return _then(_PatientNotesListState(
notes: null == notes ? _self._notes : notes // ignore: cast_nullable_to_non_nullable
as List<PatientNote>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,dateFrom: freezed == dateFrom ? _self.dateFrom : dateFrom // ignore: cast_nullable_to_non_nullable
as DateTime?,dateTo: freezed == dateTo ? _self.dateTo : dateTo // ignore: cast_nullable_to_non_nullable
as DateTime?,sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as PatientNotesSortOption,
  ));
}


}

// dart format on
