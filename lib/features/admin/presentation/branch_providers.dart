import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spine_clinic_app/core/utils/local_settings_service.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';

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
    final Staff? user = ref.watch(currentUserProvider).value;
    if (user != null && user.branch != null) {
      return user.branch!;
    }

    final LocalSettingsService service = ref.watch(localSettingsServiceProvider);
    return service.getActiveBranch();
  }

  /// Synchronously switches the active branch selection and commits it to disk.
  Future<void> setBranch(ClinicLocation location) async {
    state = location;
    
    final LocalSettingsService service = ref.read(localSettingsServiceProvider);
    await service.setActiveBranch(location);

    final Staff? user = ref.read(currentUserProvider).value;
    if (user != null) {
      final Staff updated = user.copyWith(branch: location);
      await ref.read(authRepositoryProvider).updateStaffProfile(
        staff: updated,
      );
    }
  }
}

/// Notifier for [adminBranchFilterProvider].
class AdminBranchFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? value) => state = value;
}

/// Admin branch override for the appointments dashboard.
///
/// `null` means "All Branches" (no clinic filter). When set to a specific
/// `dbValue` string, only that branch's appointments are shown. Used by
/// [_BranchDropdown] in the receptionist appointments screen header.
final adminBranchFilterProvider =
    NotifierProvider<AdminBranchFilterNotifier, String?>(
  AdminBranchFilterNotifier.new,
);
