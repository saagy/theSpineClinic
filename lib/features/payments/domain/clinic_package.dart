/// Freezed model representing elements in the `packages` JSONB field of the `clinic_settings` table.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

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

/// A package package configure in the clinic settings.
@freezed
abstract class ClinicPackage with _$ClinicPackage {
  /// Creates a [ClinicPackage].
  const factory ClinicPackage({
    required String name,
    @JsonKey(name: 'session_count') required int sessionCount,
    @JsonKey(fromJson: _priceFromJson, toJson: _priceToJson) required double price,
  }) = _ClinicPackage;

  /// Deserialises from a JSON map.
  factory ClinicPackage.fromJson(Map<String, dynamic> json) =>
      _$ClinicPackageFromJson(json);
}
