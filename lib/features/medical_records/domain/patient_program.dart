library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:spine_clinic_app/features/medical_records/domain/body_region.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_condition.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_status.dart';
import 'package:spine_clinic_app/features/medical_records/domain/treatment_plan.dart';

part 'patient_program.freezed.dart';
part 'patient_program.g.dart';

/// Represents a comprehensive rehabilitation program episode for a patient.
@freezed
abstract class PatientProgram with _$PatientProgram {
  const PatientProgram._();

  const factory PatientProgram({
    required String id,
    @JsonKey(name: 'patient_id') required String patientId,
    @JsonKey(name: 'created_by') required String createdBy,
    @Default(ProgramStatus.active) ProgramStatus status,
    String? examination,
    @JsonKey(name: 'imaging_notes') String? imagingNotes,
    @JsonKey(name: 'exaggerating_positions') String? exaggeratingPositions,
    @JsonKey(name: 'relieving_positions') String? relievingPositions,
    String? notes,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'program_conditions')
    @Default([])
    List<ProgramCondition> conditions,
    @JsonKey(name: 'treatment_plans')
    @Default([])
    List<TreatmentPlan> treatmentPlans,
  }) = _PatientProgram;

  factory PatientProgram.fromJson(Map<String, dynamic> json) =>
      _$PatientProgramFromJson(json);

  /// Resolves the currently active treatment plan in this program.
  TreatmentPlan? get activePlan {
    for (final plan in treatmentPlans) {
      if (plan.isActive) return plan;
    }
    return treatmentPlans.firstOrNull;
  }

  /// Derived unique list of affected body regions from selected conditions.
  Set<BodyRegion> get affectedRegions {
    final regions = <BodyRegion>{};
    for (final pc in conditions) {
      if (pc.condition != null) {
        regions.add(pc.condition!.region);
      }
    }
    return regions;
  }
}
