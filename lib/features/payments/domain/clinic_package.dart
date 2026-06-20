/// Freezed model representing elements in the `packages` JSONB field of the `clinic_settings` table.
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:spine_clinic_app/features/payments/domain/package_kind.dart';

part 'clinic_package.freezed.dart';
part 'clinic_package.g.dart';

double _priceFromJson(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? 0.0;
  }
  return 0.0;
}

Object _priceToJson(double value) => value;

/// A package configured in the clinic settings.
///
/// `sessionCount` represents the bundled Normal PT sessions.
/// `tractionsCount` represents the bundled Spinal Traction sessions.
/// Combined packages use both; pure Session / pure Traction packages
/// leave the other at 0.
@freezed
abstract class ClinicPackage with _$ClinicPackage {
  /// Creates a [ClinicPackage].
  const factory ClinicPackage({
    required String name,
    @JsonKey(name: 'kind') @Default(PackageKind.session) PackageKind kind,
    @JsonKey(name: 'session_count') @Default(0) int sessionCount,
    @JsonKey(name: 'tractions_count') @Default(0) int tractionsCount,
    @JsonKey(fromJson: _priceFromJson, toJson: _priceToJson) required double price,
  }) = _ClinicPackage;

  /// Deserialises from a JSON map.
  factory ClinicPackage.fromJson(Map<String, dynamic> json) =>
      _$ClinicPackageFromJson(json);
}
