import 'package:shared_preferences/shared_preferences.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';

/// Manages local device storage settings such as active branch preferences.
class LocalSettingsService {
  /// Creates a [LocalSettingsService] backed by [SharedPreferences].
  LocalSettingsService(this._prefs);

  final SharedPreferences _prefs;
  static const String _activeBranchKey = 'active_branch_preference';

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
}
