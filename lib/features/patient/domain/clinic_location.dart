/// Clinic location enum mapping to Supabase `clinic_location` type.
///
/// Values: `'tagamoa'` | `'masr_elgedida'` (AGENT_CONTEXT §3).
/// Display labels come from [AppStrings] (Rule 7).
library;

import 'package:json_annotation/json_annotation.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';

/// Physical clinic branch where a patient is registered.
@JsonEnum(valueField: 'dbValue')
enum ClinicLocation {
  /// Tagamoa branch.
  tagamoa('tagamoa'),

  /// Masr El-Gedida branch.
  masrElgedida('masr_elgedida');

  const ClinicLocation(this.dbValue);

  /// The raw string stored in the `patients.clinic` column.
  final String dbValue;

  /// Human-readable display label from [AppStrings].
  String get displayLabel => switch (this) {
    ClinicLocation.tagamoa => AppStrings.clinicTagamoa,
    ClinicLocation.masrElgedida => AppStrings.clinicMasrElgedida,
  };
}
