library;

import 'dart:typed_data';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_status.dart';
import 'package:spine_clinic_app/features/medical_records/domain/treatment_plan_input.dart';

/// Represents a raw imaging file to attach atomically with a program.
class ProgramAttachment {
  const ProgramAttachment({
    required this.fileName,
    required this.bytes,
  });

  final String fileName;
  final Uint8List bytes;
}

/// Domain contract for patient rehabilitation programs.
abstract class ProgramRepository {
  /// Fetches all programs for a patient ordered by creation date descending.
  Future<Result<List<PatientProgram>>> getProgramsForPatient(String patientId);

  /// Fetches a single program by its [programId] with conditions and plans joined.
  Future<Result<PatientProgram?>> getProgramById(String programId);

  /// Creates a new patient program atomically via PostgreSQL RPC.
  Future<Result<PatientProgram>> createProgram({
    required String patientId,
    required List<String> conditionIds,
    String? examination,
    String? imagingNotes,
    String? exaggeratingPositions,
    String? relievingPositions,
    String? notes,
    List<ProgramAttachment>? pendingAttachments,
    TreatmentPlanInput? treatmentPlan,
  });

  /// Updates an existing patient program atomically via PostgreSQL RPC.
  Future<Result<PatientProgram>> updateProgram({
    required String programId,
    required String patientId,
    required List<String> conditionIds,
    String? examination,
    String? imagingNotes,
    String? exaggeratingPositions,
    String? relievingPositions,
    String? notes,
    ProgramStatus? status,
    List<ProgramAttachment>? pendingAttachments,
    TreatmentPlanInput? treatmentPlan,
  });

  /// Updates only the status of a program (e.g. active, completed, archived).
  Future<Result<void>> updateProgramStatus({
    required String programId,
    required ProgramStatus status,
  });

  /// Deletes a program by its [programId].
  Future<Result<void>> deleteProgram(String programId);
}
