import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';

/// Manages local device storage settings such as active branch and
/// preferred [ThemeMode] for the manual light/system/dark toggle.
class LocalSettingsService {
  /// Creates a [LocalSettingsService] backed by [SharedPreferences].
  LocalSettingsService(this._prefs);

  final SharedPreferences _prefs;
  static const String _activeBranchKey = 'active_branch_preference';
  static const String _themeModeKey = 'theme_mode_preference';

  /// Gets the persisted clinic location preference. Defaults to [ClinicLocation.tagamoa].
  ClinicLocation getActiveBranch() {
    final String? val = _prefs.getString(_activeBranchKey);
    if (val == null) return ClinicLocation.tagamoa;

    return ClinicLocation.values.firstWhere(
      (loc) => loc.dbValue == val,
      orElse: () => ClinicLocation.tagamoa,
    );
  }

  /// Persists the active clinic branch choice to local disk storage.
  Future<bool> setActiveBranch(ClinicLocation location) async {
    return _prefs.setString(_activeBranchKey, location.dbValue);
  }

  /// Gets the persisted [ThemeMode]. Defaults to [ThemeMode.light] so
  /// the app always opens in light mode even on phones set to dark.
  ThemeMode getThemeMode() {
    final String? value = _prefs.getString(_themeModeKey);
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
  }

  /// Persists the active [ThemeMode].
  Future<bool> setThemeMode(ThemeMode mode) {
    return _prefs.setString(_themeModeKey, mode.name);
  }
}
