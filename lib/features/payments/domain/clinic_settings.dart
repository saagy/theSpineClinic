/// Freezed model for the `public.clinic_settings` table.
///
/// Maps 1:1 to the Supabase schema (AGENT_CONTEXT §3).
/// Rule 4 — repositories wrap this in `Result<T>`.
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:spine_clinic_app/features/payments/domain/clinic_package.dart';

part 'clinic_settings.freezed.dart';
part 'clinic_settings.g.dart';

/// The single-row clinic settings config in the Spine Clinic system.
@freezed
abstract class ClinicSettings with _$ClinicSettings {
  /// Creates a [ClinicSettings] instance.
  const factory ClinicSettings({
    required String id,
    required List<ClinicPackage> packages,
    @JsonKey(name: 'updated_by') String? updatedBy,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _ClinicSettings;

  /// Deserialises from a Supabase JSON row.
  factory ClinicSettings.fromJson(Map<String, dynamic> json) =>
      _$ClinicSettingsFromJson(json);
}
