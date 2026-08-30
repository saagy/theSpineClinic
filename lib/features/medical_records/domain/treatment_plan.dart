library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:spine_clinic_app/features/medical_records/domain/plan_modality.dart';

part 'treatment_plan.freezed.dart';
part 'treatment_plan.g.dart';

/// Represents a treatment plan version containing a suite of prescribed modalities.
@freezed
abstract class TreatmentPlan with _$TreatmentPlan {
  const factory TreatmentPlan({
    required String id,
    @JsonKey(name: 'program_id') required String programId,
    @JsonKey(name: 'created_by') required String createdBy,
    @JsonKey(name: 'plan_name') @Default('Plan 1') String planName,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    String? notes,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'plan_modalities')
    @Default([])
    List<PlanModality> modalities,
  }) = _TreatmentPlan;

  factory TreatmentPlan.fromJson(Map<String, dynamic> json) =>
      _$TreatmentPlanFromJson(json);
}
