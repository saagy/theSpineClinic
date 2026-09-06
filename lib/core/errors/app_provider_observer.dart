import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';

/// Riverpod ProviderObserver that captures unexpected state notifier failures
/// and logs them to Sentry.
base class AppProviderObserver extends ProviderObserver {
  const AppProviderObserver();

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    // If it's already an AppException, ErrorReporter has already evaluated it.
    if (error is! AppException) {
      Sentry.captureException(
        StateError('Unexpected provider failure (${error.runtimeType})'),
        stackTrace: stackTrace,
        withScope: (scope) {
          scope.setTag(
            'provider_name',
            context.provider.name ?? context.provider.runtimeType.toString(),
          );
        },
      );
    }
  }
}
