/// Clinic location enum mapping to Supabase `clinic_location` type.
///
/// This enum is the single app-side list of branches. Screens, filters and
/// pickers iterate [ClinicLocation.values]; never list branches by hand.
/// Adding a branch: see "Adding a branch" in `docs/database-schema.md`.
library;

import 'package:json_annotation/json_annotation.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';

/// Physical clinic branch where a patient is registered.
@JsonEnum(valueField: 'dbValue')
enum ClinicLocation {
  /// Tagamoa branch.
  tagamoa('tagamoa', 'TG'),

  /// Masr El-Gedida branch.
  masrElgedida('masr_elgedida', 'MG'),

  /// Madinaty branch.
  madinaty('madinaty', 'MD');

  const ClinicLocation(this.dbValue, this.documentPrefix);

  /// The raw string stored in the `clinic_location` database enum.
  final String dbValue;

  /// Prefix printed on this branch's invoice, receipt and refund numbers.
  final String documentPrefix;

  /// Human-readable display label from [AppStrings].
  String get displayLabel => switch (this) {
    ClinicLocation.tagamoa => AppStrings.clinicTagamoa,
    ClinicLocation.masrElgedida => AppStrings.clinicMasrElgedida,
    ClinicLocation.madinaty => AppStrings.clinicMadinaty,
  };

  /// The branch stored as [value], or `null` when unknown or absent.
  static ClinicLocation? fromDbValue(String? value) {
    for (final ClinicLocation branch in values) {
      if (branch.dbValue == value) return branch;
    }
    return null;
  }
}
