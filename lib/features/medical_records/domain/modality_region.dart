library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:spine_clinic_app/features/medical_records/domain/laterality.dart';

part 'modality_region.freezed.dart';
part 'modality_region.g.dart';

/// Target body region and duration configuration for a treatment modality.
@freezed
abstract class ModalityRegion with _$ModalityRegion {
  const factory ModalityRegion({
    required String id,
    @JsonKey(name: 'plan_modality_id') required String planModalityId,
    @JsonKey(name: 'target_region') required String targetRegion,
    Laterality? laterality,
    @JsonKey(name: 'time_minutes') @Default(15) int timeMinutes,
  }) = _ModalityRegion;

  factory ModalityRegion.fromJson(Map<String, dynamic> json) =>
      _$ModalityRegionFromJson(json);
}
