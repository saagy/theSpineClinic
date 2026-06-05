/// Core exception types for the Spine Clinic application.
///
/// All repository methods must catch raw Supabase exceptions and convert
/// them into one of these subtypes via [AppException.fromSupabaseException].
/// This ensures no raw SQL or stack traces leak to the presentation layer.
library;

import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Base class for all application-level exceptions.
///
/// Every subclass carries:
/// - [code]  – a machine-readable identifier for programmatic branching.
/// - [message] – a developer-facing description (logs only, never shown to users).
/// - [userMessageKey] – a key into [AppStrings] for the user-facing message.
sealed class AppException implements Exception {
  const AppException({
    required this.code,
    required this.message,
    required this.userMessageKey,
  });

  /// Machine-readable error code (e.g. 'auth/invalid-credentials').
  final String code;

  /// Developer-facing detail for logs. Never display to users.
  final String message;

  /// Key that maps to a localised string in [AppStrings].
  final String userMessageKey;

  /// Normalises any Supabase-originating exception into a typed
  /// [AppException] subclass.
  ///
  /// Handles:
  /// - [supabase.AuthException] → [AuthException]
  /// - [supabase.PostgrestException] → [DatabaseException]
  /// - [SocketException] → [NetworkException]
  /// - Everything else → [UnknownException]
  static AppException fromSupabaseException(Object error) {
    if (error is supabase.AuthException) {
      return AuthException._fromAuth(error);
    }

    if (error is supabase.PostgrestException) {
      return DatabaseException._fromPostgrest(error);
    }

    if (error is SocketException) {
      return NetworkException(
        code: 'network/socket-error',
        message: error.message,
      );
    }

    return UnknownException(
      message: error.toString(),
    );
  }

  @override
  String toString() => 'AppException($code): $message';
}

/// Failures related to authentication and session management.
class AuthException extends AppException {
  const AuthException({
    required super.code,
    required super.message,
    super.userMessageKey = 'error_auth_generic',
  });

  factory AuthException._fromAuth(supabase.AuthException error) {
    final String msg = error.message.toLowerCase();

    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid credentials')) {
      return AuthException(
        code: 'auth/invalid-credentials',
        message: error.message,
        userMessageKey: 'error_auth_invalid_credentials',
      );
    }

    if (msg.contains('email not confirmed')) {
      return AuthException(
        code: 'auth/email-not-confirmed',
        message: error.message,
        userMessageKey: 'error_auth_email_not_confirmed',
      );
    }

    if (msg.contains('user already registered') ||
        msg.contains('already been registered')) {
      return AuthException(
        code: 'auth/user-already-exists',
        message: error.message,
        userMessageKey: 'error_auth_user_already_exists',
      );
    }

    if (msg.contains('session') || msg.contains('refresh_token')) {
      return AuthException(
        code: 'auth/session-expired',
        message: error.message,
        userMessageKey: 'error_auth_session_expired',
      );
    }

    // Rate-limit (HTTP 429 "Too Many Requests")
    if (msg.contains('rate limit') ||
        msg.contains('too many requests') ||
        error.statusCode == '429') {
      return AuthException(
        code: 'auth/rate-limited',
        message: error.message,
        userMessageKey: 'error_auth_rate_limited',
      );
    }

    return AuthException(
      code: 'auth/unknown',
      message: error.message,
    );
  }
}

/// Failures originating from Postgrest / database operations.
class DatabaseException extends AppException {
  const DatabaseException({
    required super.code,
    required super.message,
    super.userMessageKey = 'error_database_generic',
    this.pgCode,
  });

  /// The raw Postgres error code (e.g. '23503', '42501') when available.
  final String? pgCode;

  factory DatabaseException._fromPostgrest(
    supabase.PostgrestException error,
  ) {
    final String? pgCode = error.code;

    // HTTP 401 Unauthorized — no active session / RLS blocked
    final int? httpStatus = int.tryParse('${error.code}');
    if (httpStatus == 401 ||
        error.message.toLowerCase().contains('jwt') ||
        error.message.toLowerCase().contains('not authenticated')) {
      return DatabaseException(
        code: 'db/unauthorized',
        message: error.message,
        userMessageKey: 'error_auth_generic',
        pgCode: pgCode,
      );
    }

    // RLS violation — user lacks permission
    if (pgCode == '42501') {
      return DatabaseException(
        code: 'db/rls-violation',
        message: error.message,
        userMessageKey: 'error_database_permission_denied',
        pgCode: pgCode,
      );
    }

    // Foreign key violation — referencing non-existent record
    if (pgCode == '23503') {
      return DatabaseException(
        code: 'db/foreign-key-violation',
        message: error.message,
        userMessageKey: 'error_database_reference_not_found',
        pgCode: pgCode,
      );
    }

    // Unique constraint violation — duplicate record
    if (pgCode == '23505') {
      return DatabaseException(
        code: 'db/unique-violation',
        message: error.message,
        userMessageKey: 'error_database_duplicate_record',
        pgCode: pgCode,
      );
    }

    // Not-null violation — required field missing
    if (pgCode == '23502') {
      return DatabaseException(
        code: 'db/not-null-violation',
        message: error.message,
        userMessageKey: 'error_database_required_field_missing',
        pgCode: pgCode,
      );
    }

    // Check constraint violation
    if (pgCode == '23514') {
      return DatabaseException(
        code: 'db/check-violation',
        message: error.message,
        userMessageKey: 'error_database_validation_failed',
        pgCode: pgCode,
      );
    }

    // PGRST-family codes (PostgREST layer, not raw Postgres)
    final String pgrstCode = error.code ?? '';
    if (pgrstCode.startsWith('PGRST')) {
      return DatabaseException(
        code: 'db/postgrest-$pgrstCode',
        message: error.message,
        userMessageKey: 'error_database_query_failed',
        pgCode: pgrstCode,
      );
    }

    return DatabaseException(
      code: 'db/unknown',
      message: error.message,
      pgCode: pgCode,
    );
  }
}

/// Connection or timeout failures.
class NetworkException extends AppException {
  const NetworkException({
    required super.code,
    required super.message,
    super.userMessageKey = 'error_network_generic',
  });
}

/// Catch-all for truly unexpected errors.
class UnknownException extends AppException {
  const UnknownException({
    required super.message,
    super.code = 'unknown',
    super.userMessageKey = 'error_unknown',
  });
}
