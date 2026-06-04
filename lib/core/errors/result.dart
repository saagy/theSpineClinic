/// A discriminated union that forces every repository consumer to handle
/// both success and failure paths at compile time.
///
/// Usage in a repository:
/// ```dart
/// Future<Result<Patient>> getPatient(String id) async {
///   try {
///     final data = await _service.from('patients').select().eq('id', id).single();
///     return Result.success(Patient.fromJson(data));
///   } on Exception catch (e) {
///     return Result.failure(AppException.fromSupabaseException(e));
///   }
/// }
/// ```
///
/// Usage in a Riverpod notifier:
/// ```dart
/// final result = await ref.read(patientRepositoryProvider).getPatient(id);
/// result.when(
///   success: (patient) => state = AsyncValue.data(patient),
///   failure: (error) => state = AsyncValue.error(error, StackTrace.current),
/// );
/// ```
library;

import 'package:spine_clinic_app/core/errors/app_exception.dart';

/// Sealed result wrapper returned by every repository method.
///
/// Dart's exhaustiveness checking guarantees the caller handles both
/// [Success] and [Failure] — no silent swallowing of errors.
sealed class Result<T> {
  const Result();

  /// Convenience constructor for the success case.
  const factory Result.success(T data) = Success<T>;

  /// Convenience constructor for the failure case.
  const factory Result.failure(AppException exception) = Failure<T>;

  /// Exhaustive fold — forces the caller to handle both branches.
  R when<R>({
    required R Function(T data) success,
    required R Function(AppException exception) failure,
  });

  /// Returns `true` when this result carries a data payload.
  bool get isSuccess => this is Success<T>;

  /// Returns `true` when this result carries an exception.
  bool get isFailure => this is Failure<T>;

  /// Unwraps the data payload or returns `null` for failures.
  T? get dataOrNull => switch (this) {
    Success<T>(:final T data) => data,
    Failure<T>() => null,
  };

  /// Unwraps the exception or returns `null` for successes.
  AppException? get exceptionOrNull => switch (this) {
    Success<T>() => null,
    Failure<T>(:final AppException exception) => exception,
  };

  /// Transforms the success payload while preserving failures.
  Result<R> map<R>(R Function(T data) transform) => switch (this) {
    Success<T>(:final T data) => Result<R>.success(transform(data)),
    Failure<T>(:final AppException exception) => Result<R>.failure(exception),
  };

  /// Chains an async operation that itself returns a [Result].
  Future<Result<R>> flatMap<R>(
    Future<Result<R>> Function(T data) transform,
  ) async =>
      switch (this) {
        Success<T>(:final T data) => await transform(data),
        Failure<T>(:final AppException exception) =>
          Result<R>.failure(exception),
      };
}

/// The success branch of [Result], carrying a [data] payload.
final class Success<T> extends Result<T> {
  const Success(this.data);

  /// The successfully produced value.
  final T data;

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(AppException exception) failure,
  }) =>
      success(data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'Success<$T>($data)';
}

/// The failure branch of [Result], carrying an [AppException].
final class Failure<T> extends Result<T> {
  const Failure(this.exception);

  /// The structured exception describing what went wrong.
  final AppException exception;

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(AppException exception) failure,
  }) =>
      failure(exception);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> &&
          runtimeType == other.runtimeType &&
          exception == other.exception;

  @override
  int get hashCode => exception.hashCode;

  @override
  String toString() => 'Failure<$T>(${exception.code}: ${exception.message})';
}
