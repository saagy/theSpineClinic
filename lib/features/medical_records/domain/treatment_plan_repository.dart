library;

import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_input.dart';
import 'package:spine_clinic_app/features/medical_records/domain/treatment_plan.dart';

/// Domain repository contract for treatment plan management.
abstract class TreatmentPlanRepository {
  /// Atomically creates or updates a treatment plan with modalities and regions.
  Future<Result<TreatmentPlan>> upsertPlan({
    required String programId,
    String? planId,
    required String planName,
    required bool isActive,
    String? notes,
    required List<ModalityInput> modalities,
  });

  /// Atomically switches the active treatment plan for a program.
  Future<Result<void>> activatePlan({
    required String planId,
    required String programId,
  });

  /// Atomically deletes a treatment plan by its ID.
  Future<Result<void>> deletePlan(String planId);
}
