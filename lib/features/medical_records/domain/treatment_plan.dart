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
    @JsonKey(name: 'plan_modalities', readValue: _modalitiesInChosenOrder)
    @Default([])
    List<PlanModality> modalities,
  }) = _TreatmentPlan;

  factory TreatmentPlan.fromJson(Map<String, dynamic> json) =>
      _$TreatmentPlanFromJson(json);
}

/// Queries and save RPCs return modality rows unordered, so the order the
/// doctor chose is restored once here for every read path.
Object? _modalitiesInChosenOrder(Map<dynamic, dynamic> json, String key) {
  final rows = json[key] as List<dynamic>?;
  if (rows == null) return null;
  num orderOf(dynamic row) => (row as Map<String, dynamic>)['sort_order'] as num? ?? 0;
  return [...rows]..sort((a, b) => orderOf(a).compareTo(orderOf(b)));
}
