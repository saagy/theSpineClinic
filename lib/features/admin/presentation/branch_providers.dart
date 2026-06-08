import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spine_clinic_app/core/utils/local_settings_service.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';

part 'branch_providers.g.dart';

/// Exposes the global, pre-initialized [SharedPreferences] instance.
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main()');
}

/// Exposes the [LocalSettingsService] backend.
@Riverpod(keepAlive: true)
LocalSettingsService localSettingsService(Ref ref) {
  final SharedPreferences prefs = ref.watch(sharedPreferencesProvider);
  return LocalSettingsService(prefs);
}

/// Active branch state notifier. Synchronously exposes choices and persists updates.
@riverpod
class ActiveBranch extends _$ActiveBranch {
  @override
  ClinicLocation build() {
    final LocalSettingsService service = ref.watch(localSettingsServiceProvider);
    return service.getActiveBranch();
  }

  /// Synchronously switches the active branch selection and commits it to disk.
  Future<void> setBranch(ClinicLocation location) async {
    state = location;
    final LocalSettingsService service = ref.read(localSettingsServiceProvider);
    await service.setActiveBranch(location);
  }
}
