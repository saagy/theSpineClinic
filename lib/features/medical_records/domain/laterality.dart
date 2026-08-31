library;

import 'package:json_annotation/json_annotation.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';

/// Laterality (side selection) for bilateral body regions.
@JsonEnum(valueField: 'dbValue')
enum Laterality {
  right('right'),
  left('left'),
  both('both');

  const Laterality(this.dbValue);

  final String dbValue;

  String get displayLabel => switch (this) {
        Laterality.right => AppStrings.lateralityRight,
        Laterality.left => AppStrings.lateralityLeft,
        Laterality.both => AppStrings.lateralityBoth,
      };

  String get shortLabel => switch (this) {
        Laterality.right => 'Right',
        Laterality.left => 'Left',
        Laterality.both => 'Both',
      };
}
