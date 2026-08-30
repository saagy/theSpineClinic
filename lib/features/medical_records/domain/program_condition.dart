library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:spine_clinic_app/features/medical_records/domain/condition_catalog.dart';

part 'program_condition.freezed.dart';
part 'program_condition.g.dart';

/// Junction link between a program and a selected condition.
@freezed
abstract class ProgramCondition with _$ProgramCondition {
  const factory ProgramCondition({
    required String id,
    @JsonKey(name: 'program_id') required String programId,
    @JsonKey(name: 'condition_id') required String conditionId,
    @JsonKey(name: 'condition_catalog') ConditionCatalog? condition,
  }) = _ProgramCondition;

  factory ProgramCondition.fromJson(Map<String, dynamic> json) =>
      _$ProgramConditionFromJson(json);
}
