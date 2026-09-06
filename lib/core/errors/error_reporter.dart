import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';

/// Evaluates application exceptions and reports unexpected database, RLS,
/// storage, and server-side errors to Sentry while filtering normal user flows.
abstract final class ErrorReporter {
  /// Evaluates the exception and dispatches it to Sentry if it is a system or DB failure.
  static void reportIfUnexpected(Object rawError, AppException appException) {
    // 1. Filter out expected user authentication actions
    if (appException is AuthException) {
      final code = appException.code;
      if (code == 'auth/invalid-credentials' ||
          code == 'auth/user-already-exists' ||
          code == 'auth/email-not-confirmed' ||
          code == 'auth/session-expired') {
        return;
      }
    }

    // 2. Filter out normal record-not-found lookups
    if (appException is NotFoundException) {
      return;
    }

    // 3. Filter out predictable business validation rules
    if (appException is DatabaseException) {
      final code = appException.code;
      if (code == 'db/insufficient-package-balance' ||
          code == 'db/due-booking-changed') {
        return;
      }
    }

    // 4. Dispatch actual database bugs (RLS 42501, FK 23503, Unique 23505, RPC errors, 500s)
    Sentry.captureException(
      StateError('Application failure (${appException.code})'),
      stackTrace: StackTrace.current,
      withScope: (scope) {
        scope.setTag('error_code', appException.code);
        if (appException is DatabaseException && appException.pgCode != null) {
          scope.setTag('pg_code', appException.pgCode!);
        }
      },
    );
  }
}
