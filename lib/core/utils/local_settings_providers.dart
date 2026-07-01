import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spine_clinic_app/core/utils/local_settings_service.dart';

part 'local_settings_providers.g.dart';

/// Exposes the global, pre-initialized [SharedPreferences] instance.
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main()',
  );
}

/// Exposes the local settings persistence backend.
@Riverpod(keepAlive: true)
LocalSettingsService localSettingsService(Ref ref) {
  final SharedPreferences prefs = ref.watch(sharedPreferencesProvider);
  return LocalSettingsService(prefs);
}
