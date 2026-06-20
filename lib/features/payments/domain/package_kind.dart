/// Package kind discriminator for `clinic_settings.packages[*].kind` JSONB.
///
/// Persisted as lowercase strings: 'session' | 'traction' | 'combined'.
library;

import 'package:json_annotation/json_annotation.dart';

/// What a clinic package delivers to a patient.
@JsonEnum(valueField: 'dbValue')
enum PackageKind {
  /// Bundles only Normal PT sessions.
  session('session'),

  /// Bundles only Spinal Traction sessions.
  traction('traction'),

  /// Bundles both PT and Traction sessions in a single price.
  combined('combined');

  const PackageKind(this.dbValue);

  /// The raw string stored in the database.
  final String dbValue;

  /// Which balance buckets this kind credits.
  ///
  /// Returned as a set keyed by [PackageKind] so callers can map
  /// "kind → list of buckets" without conditionals.
  bool get creditsSessionBalance => switch (this) {
        PackageKind.session => true,
        PackageKind.traction => false,
        PackageKind.combined => true,
      };

  /// Whether this kind credits the traction balance.
  bool get creditsTractionBalance => switch (this) {
        PackageKind.session => false,
        PackageKind.traction => true,
        PackageKind.combined => true,
      };
}
