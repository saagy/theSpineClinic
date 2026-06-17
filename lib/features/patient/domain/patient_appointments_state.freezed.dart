// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'patient_appointments_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PatientAppointmentsState {

 List<Appointment> get appointments; bool get isLoading; bool get isLoadingMore; bool get hasMore; int get totalCount; String? get errorMessage; Set<AppointmentStatus>? get statusFilter; Set<AppointmentType>? get typeFilter; DateTime? get dateFrom; DateTime? get dateTo; String? get doctorId; bool? get usePackageFilter; PatientAppointmentSortOption get sort;
/// Create a copy of PatientAppointmentsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PatientAppointmentsStateCopyWith<PatientAppointmentsState> get copyWith => _$PatientAppointmentsStateCopyWithImpl<PatientAppointmentsState>(this as PatientAppointmentsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PatientAppointmentsState&&const DeepCollectionEquality().equals(other.appointments, appointments)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&const DeepCollectionEquality().equals(other.statusFilter, statusFilter)&&const DeepCollectionEquality().equals(other.typeFilter, typeFilter)&&(identical(other.dateFrom, dateFrom) || other.dateFrom == dateFrom)&&(identical(other.dateTo, dateTo) || other.dateTo == dateTo)&&(identical(other.doctorId, doctorId) || other.doctorId == doctorId)&&(identical(other.usePackageFilter, usePackageFilter) || other.usePackageFilter == usePackageFilter)&&(identical(other.sort, sort) || other.sort == sort));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(appointments),isLoading,isLoadingMore,hasMore,totalCount,errorMessage,const DeepCollectionEquality().hash(statusFilter),const DeepCollectionEquality().hash(typeFilter),dateFrom,dateTo,doctorId,usePackageFilter,sort);

@override
String toString() {
  return 'PatientAppointmentsState(appointments: $appointments, isLoading: $isLoading, isLoadingMore: $isLoadingMore, hasMore: $hasMore, totalCount: $totalCount, errorMessage: $errorMessage, statusFilter: $statusFilter, typeFilter: $typeFilter, dateFrom: $dateFrom, dateTo: $dateTo, doctorId: $doctorId, usePackageFilter: $usePackageFilter, sort: $sort)';
}


}

/// @nodoc
abstract mixin class $PatientAppointmentsStateCopyWith<$Res>  {
  factory $PatientAppointmentsStateCopyWith(PatientAppointmentsState value, $Res Function(PatientAppointmentsState) _then) = _$PatientAppointmentsStateCopyWithImpl;
@useResult
$Res call({
 List<Appointment> appointments, bool isLoading, bool isLoadingMore, bool hasMore, int totalCount, String? errorMessage, Set<AppointmentStatus>? statusFilter, Set<AppointmentType>? typeFilter, DateTime? dateFrom, DateTime? dateTo, String? doctorId, bool? usePackageFilter, PatientAppointmentSortOption sort
});




}
/// @nodoc
class _$PatientAppointmentsStateCopyWithImpl<$Res>
    implements $PatientAppointmentsStateCopyWith<$Res> {
  _$PatientAppointmentsStateCopyWithImpl(this._self, this._then);

  final PatientAppointmentsState _self;
  final $Res Function(PatientAppointmentsState) _then;

/// Create a copy of PatientAppointmentsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? appointments = null,Object? isLoading = null,Object? isLoadingMore = null,Object? hasMore = null,Object? totalCount = null,Object? errorMessage = freezed,Object? statusFilter = freezed,Object? typeFilter = freezed,Object? dateFrom = freezed,Object? dateTo = freezed,Object? doctorId = freezed,Object? usePackageFilter = freezed,Object? sort = null,}) {
  return _then(_self.copyWith(
appointments: null == appointments ? _self.appointments : appointments // ignore: cast_nullable_to_non_nullable
as List<Appointment>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,statusFilter: freezed == statusFilter ? _self.statusFilter : statusFilter // ignore: cast_nullable_to_non_nullable
as Set<AppointmentStatus>?,typeFilter: freezed == typeFilter ? _self.typeFilter : typeFilter // ignore: cast_nullable_to_non_nullable
as Set<AppointmentType>?,dateFrom: freezed == dateFrom ? _self.dateFrom : dateFrom // ignore: cast_nullable_to_non_nullable
as DateTime?,dateTo: freezed == dateTo ? _self.dateTo : dateTo // ignore: cast_nullable_to_non_nullable
as DateTime?,doctorId: freezed == doctorId ? _self.doctorId : doctorId // ignore: cast_nullable_to_non_nullable
as String?,usePackageFilter: freezed == usePackageFilter ? _self.usePackageFilter : usePackageFilter // ignore: cast_nullable_to_non_nullable
as bool?,sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as PatientAppointmentSortOption,
  ));
}

}


/// Adds pattern-matching-related methods to [PatientAppointmentsState].
extension PatientAppointmentsStatePatterns on PatientAppointmentsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PatientAppointmentsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PatientAppointmentsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PatientAppointmentsState value)  $default,){
final _that = this;
switch (_that) {
case _PatientAppointmentsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PatientAppointmentsState value)?  $default,){
final _that = this;
switch (_that) {
case _PatientAppointmentsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Appointment> appointments,  bool isLoading,  bool isLoadingMore,  bool hasMore,  int totalCount,  String? errorMessage,  Set<AppointmentStatus>? statusFilter,  Set<AppointmentType>? typeFilter,  DateTime? dateFrom,  DateTime? dateTo,  String? doctorId,  bool? usePackageFilter,  PatientAppointmentSortOption sort)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PatientAppointmentsState() when $default != null:
return $default(_that.appointments,_that.isLoading,_that.isLoadingMore,_that.hasMore,_that.totalCount,_that.errorMessage,_that.statusFilter,_that.typeFilter,_that.dateFrom,_that.dateTo,_that.doctorId,_that.usePackageFilter,_that.sort);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Appointment> appointments,  bool isLoading,  bool isLoadingMore,  bool hasMore,  int totalCount,  String? errorMessage,  Set<AppointmentStatus>? statusFilter,  Set<AppointmentType>? typeFilter,  DateTime? dateFrom,  DateTime? dateTo,  String? doctorId,  bool? usePackageFilter,  PatientAppointmentSortOption sort)  $default,) {final _that = this;
switch (_that) {
case _PatientAppointmentsState():
return $default(_that.appointments,_that.isLoading,_that.isLoadingMore,_that.hasMore,_that.totalCount,_that.errorMessage,_that.statusFilter,_that.typeFilter,_that.dateFrom,_that.dateTo,_that.doctorId,_that.usePackageFilter,_that.sort);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Appointment> appointments,  bool isLoading,  bool isLoadingMore,  bool hasMore,  int totalCount,  String? errorMessage,  Set<AppointmentStatus>? statusFilter,  Set<AppointmentType>? typeFilter,  DateTime? dateFrom,  DateTime? dateTo,  String? doctorId,  bool? usePackageFilter,  PatientAppointmentSortOption sort)?  $default,) {final _that = this;
switch (_that) {
case _PatientAppointmentsState() when $default != null:
return $default(_that.appointments,_that.isLoading,_that.isLoadingMore,_that.hasMore,_that.totalCount,_that.errorMessage,_that.statusFilter,_that.typeFilter,_that.dateFrom,_that.dateTo,_that.doctorId,_that.usePackageFilter,_that.sort);case _:
  return null;

}
}

}

/// @nodoc


class _PatientAppointmentsState implements PatientAppointmentsState {
  const _PatientAppointmentsState({final  List<Appointment> appointments = const [], this.isLoading = true, this.isLoadingMore = false, this.hasMore = false, this.totalCount = 0, this.errorMessage, final  Set<AppointmentStatus>? statusFilter, final  Set<AppointmentType>? typeFilter, this.dateFrom, this.dateTo, this.doctorId, this.usePackageFilter, this.sort = PatientAppointmentSortOption.dateNewest}): _appointments = appointments,_statusFilter = statusFilter,_typeFilter = typeFilter;
  

 final  List<Appointment> _appointments;
@override@JsonKey() List<Appointment> get appointments {
  if (_appointments is EqualUnmodifiableListView) return _appointments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_appointments);
}

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isLoadingMore;
@override@JsonKey() final  bool hasMore;
@override@JsonKey() final  int totalCount;
@override final  String? errorMessage;
 final  Set<AppointmentStatus>? _statusFilter;
@override Set<AppointmentStatus>? get statusFilter {
  final value = _statusFilter;
  if (value == null) return null;
  if (_statusFilter is EqualUnmodifiableSetView) return _statusFilter;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(value);
}

 final  Set<AppointmentType>? _typeFilter;
@override Set<AppointmentType>? get typeFilter {
  final value = _typeFilter;
  if (value == null) return null;
  if (_typeFilter is EqualUnmodifiableSetView) return _typeFilter;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(value);
}

@override final  DateTime? dateFrom;
@override final  DateTime? dateTo;
@override final  String? doctorId;
@override final  bool? usePackageFilter;
@override@JsonKey() final  PatientAppointmentSortOption sort;

/// Create a copy of PatientAppointmentsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PatientAppointmentsStateCopyWith<_PatientAppointmentsState> get copyWith => __$PatientAppointmentsStateCopyWithImpl<_PatientAppointmentsState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PatientAppointmentsState&&const DeepCollectionEquality().equals(other._appointments, _appointments)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&const DeepCollectionEquality().equals(other._statusFilter, _statusFilter)&&const DeepCollectionEquality().equals(other._typeFilter, _typeFilter)&&(identical(other.dateFrom, dateFrom) || other.dateFrom == dateFrom)&&(identical(other.dateTo, dateTo) || other.dateTo == dateTo)&&(identical(other.doctorId, doctorId) || other.doctorId == doctorId)&&(identical(other.usePackageFilter, usePackageFilter) || other.usePackageFilter == usePackageFilter)&&(identical(other.sort, sort) || other.sort == sort));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_appointments),isLoading,isLoadingMore,hasMore,totalCount,errorMessage,const DeepCollectionEquality().hash(_statusFilter),const DeepCollectionEquality().hash(_typeFilter),dateFrom,dateTo,doctorId,usePackageFilter,sort);

@override
String toString() {
  return 'PatientAppointmentsState(appointments: $appointments, isLoading: $isLoading, isLoadingMore: $isLoadingMore, hasMore: $hasMore, totalCount: $totalCount, errorMessage: $errorMessage, statusFilter: $statusFilter, typeFilter: $typeFilter, dateFrom: $dateFrom, dateTo: $dateTo, doctorId: $doctorId, usePackageFilter: $usePackageFilter, sort: $sort)';
}


}

/// @nodoc
abstract mixin class _$PatientAppointmentsStateCopyWith<$Res> implements $PatientAppointmentsStateCopyWith<$Res> {
  factory _$PatientAppointmentsStateCopyWith(_PatientAppointmentsState value, $Res Function(_PatientAppointmentsState) _then) = __$PatientAppointmentsStateCopyWithImpl;
@override @useResult
$Res call({
 List<Appointment> appointments, bool isLoading, bool isLoadingMore, bool hasMore, int totalCount, String? errorMessage, Set<AppointmentStatus>? statusFilter, Set<AppointmentType>? typeFilter, DateTime? dateFrom, DateTime? dateTo, String? doctorId, bool? usePackageFilter, PatientAppointmentSortOption sort
});




}
/// @nodoc
class __$PatientAppointmentsStateCopyWithImpl<$Res>
    implements _$PatientAppointmentsStateCopyWith<$Res> {
  __$PatientAppointmentsStateCopyWithImpl(this._self, this._then);

  final _PatientAppointmentsState _self;
  final $Res Function(_PatientAppointmentsState) _then;

/// Create a copy of PatientAppointmentsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? appointments = null,Object? isLoading = null,Object? isLoadingMore = null,Object? hasMore = null,Object? totalCount = null,Object? errorMessage = freezed,Object? statusFilter = freezed,Object? typeFilter = freezed,Object? dateFrom = freezed,Object? dateTo = freezed,Object? doctorId = freezed,Object? usePackageFilter = freezed,Object? sort = null,}) {
  return _then(_PatientAppointmentsState(
appointments: null == appointments ? _self._appointments : appointments // ignore: cast_nullable_to_non_nullable
as List<Appointment>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,statusFilter: freezed == statusFilter ? _self._statusFilter : statusFilter // ignore: cast_nullable_to_non_nullable
as Set<AppointmentStatus>?,typeFilter: freezed == typeFilter ? _self._typeFilter : typeFilter // ignore: cast_nullable_to_non_nullable
as Set<AppointmentType>?,dateFrom: freezed == dateFrom ? _self.dateFrom : dateFrom // ignore: cast_nullable_to_non_nullable
as DateTime?,dateTo: freezed == dateTo ? _self.dateTo : dateTo // ignore: cast_nullable_to_non_nullable
as DateTime?,doctorId: freezed == doctorId ? _self.doctorId : doctorId // ignore: cast_nullable_to_non_nullable
as String?,usePackageFilter: freezed == usePackageFilter ? _self.usePackageFilter : usePackageFilter // ignore: cast_nullable_to_non_nullable
as bool?,sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as PatientAppointmentSortOption,
  ));
}


}

// dart format on
