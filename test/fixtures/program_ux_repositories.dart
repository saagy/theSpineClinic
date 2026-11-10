import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_input.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_region.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_type.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/domain/plan_modality.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_repository.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_status.dart';
import 'package:spine_clinic_app/features/medical_records/domain/treatment_plan.dart';
import 'package:spine_clinic_app/features/medical_records/domain/treatment_plan_repository.dart';
import 'package:spine_clinic_app/features/medical_records/domain/treatment_plan_input.dart';
import 'workspace_data.dart';

final uxCurrentPlan = workspacePrograms.first.activePlan!.copyWith(
  planName: 'Strengthening and mobility',
  notes: 'Review movement quality at each visit.',
  modalities: const [
    PlanModality(
      id: 'modality',
      treatmentPlanId: 'plan-0',
      modalityType: ModalityType.tecar,
      regions: [ModalityRegion(id: 'region', planModalityId: 'modality', targetRegion: 'Lumbar', timeMinutes: 15)],
    ),
  ],
);
final uxPreviousPlan = uxCurrentPlan.copyWith(id: 'previous', planName: 'Initial treatment', isActive: false);

class ProgramUxRepository implements ProgramRepository {
  PatientProgram? program = workspacePrograms.first.copyWith(treatmentPlans: [uxCurrentPlan, uxPreviousPlan]);
  int statusWrites = 0;
  int edits = 0;
  bool failSave = false;
  @override
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
    List<String> removedDocumentIds = const [],
    TreatmentPlanInput? treatmentPlan,
  }) async {
    edits++;
    if (failSave) return const Result.failure(NetworkException(code: 'test/offline', message: 'Offline'));
    program = program!.copyWith(
      examination: examination,
      imagingNotes: imagingNotes,
      exaggeratingPositions: exaggeratingPositions,
      relievingPositions: relievingPositions,
      notes: notes,
    );
    return Result.success(program!);
  }

  @override
  Future<Result<PatientProgram?>> getProgramById(String programId) async => Result.success(program);
  @override
  Future<Result<List<PatientProgram>>> getProgramsForPatient(String patientId) async =>
      Result.success([if (program != null) program!]);
  @override
  Future<Result<void>> updateProgramStatus({required String programId, required ProgramStatus status}) async {
    statusWrites++;
    program = program!.copyWith(status: status);
    return const Result.success(null);
  }

  @override
  Future<Result<void>> deleteProgram(String programId) async {
    program = null;
    return const Result.success(null);
  }

  @override
  Object? noSuchMethod(Invocation invocation) => throw UnsupportedError('${invocation.memberName}');
}

class ProgramUxPlanRepository implements TreatmentPlanRepository {
  ProgramUxPlanRepository(this.programs);
  final ProgramUxRepository programs;
  String? savedId;
  String? activatedId;
  List<ModalityInput>? savedModalities;
  @override
  Future<Result<TreatmentPlan>> upsertPlan({
    required String programId,
    String? planId,
    required String planName,
    required bool isActive,
    String? notes,
    required List<ModalityInput> modalities,
  }) async {
    savedId = planId;
    savedModalities = modalities;
    final plan = uxCurrentPlan.copyWith(id: planId ?? 'new-plan', planName: planName, isActive: isActive, notes: notes);
    programs.program = programs.program!.copyWith(
      treatmentPlans: [
        for (final item in programs.program!.treatmentPlans)
          if (item.id != plan.id) item.copyWith(isActive: isActive ? false : item.isActive),
        plan,
      ],
    );
    return Result.success(plan);
  }

  @override
  Future<Result<void>> activatePlan({required String planId, required String programId}) async {
    activatedId = planId;
    programs.program = programs.program!.copyWith(
      treatmentPlans: [for (final plan in programs.program!.treatmentPlans) plan.copyWith(isActive: plan.id == planId)],
    );
    return const Result.success(null);
  }

  @override
  Future<Result<void>> deletePlan(String planId) async {
    programs.program = programs.program!.copyWith(
      treatmentPlans: programs.program!.treatmentPlans.where((p) => p.id != planId).toList(),
    );
    return const Result.success(null);
  }
}
