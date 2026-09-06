import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';

/// Permission/validation failures need user action, not background retry loops.
Duration? retryTransientErrors(int retryCount, Object error) {
  if (error is AppException && error is! NetworkException) return null;
  return ProviderContainer.defaultRetry(retryCount, error);
}
