library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_region.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_type.dart';

part 'plan_modality.freezed.dart';
part 'plan_modality.g.dart';

/// Represents a single equipment/modality configured inside a treatment plan.
@freezed
abstract class PlanModality with _$PlanModality {
  const factory PlanModality({
    required String id,
    @JsonKey(name: 'treatment_plan_id') required String treatmentPlanId,
    @JsonKey(name: 'modality_type') required ModalityType modalityType,
    String? notes,
    @JsonKey(name: 'modality_regions')
    @Default([])
    List<ModalityRegion> regions,
  }) = _PlanModality;

  factory PlanModality.fromJson(Map<String, dynamic> json) =>
      _$PlanModalityFromJson(json);
}
