/// Appointment type enum mapping to Supabase `appointment_type` type.
///
/// Values: `'session'` | `'gehaz_shad_fakarat'` (AGENT_CONTEXT §3).
/// Display labels come from [AppStrings] (Rule 7).
library;

import 'package:json_annotation/json_annotation.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';

/// The type of appointment.
@JsonEnum(valueField: 'dbValue')
enum AppointmentType {
  /// Regular session.
  session('session'),

  /// Gehaz Shad Fakarat traction device session.
  gehazShadFakarat('gehaz_shad_fakarat');

  const AppointmentType(this.dbValue);

  /// The raw string stored in the database.
  final String dbValue;

  /// Human-readable display label from [AppStrings].
  String get displayLabel => switch (this) {
    AppointmentType.session => AppStrings.session,
    AppointmentType.gehazShadFakarat => AppStrings.gehazShadFakarat,
  };
}
