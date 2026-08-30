library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:spine_clinic_app/features/medical_records/domain/body_region.dart';

part 'condition_catalog.freezed.dart';
part 'condition_catalog.g.dart';

/// Represents a catalog injury/condition entry organized by body region.
@freezed
abstract class ConditionCatalog with _$ConditionCatalog {
  const factory ConditionCatalog({
    required String id,
    required BodyRegion region,
    @JsonKey(name: 'condition_name') required String conditionName,
    @JsonKey(name: 'display_order') @Default(0) int displayOrder,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _ConditionCatalog;

  factory ConditionCatalog.fromJson(Map<String, dynamic> json) =>
      _$ConditionCatalogFromJson(json);
}
