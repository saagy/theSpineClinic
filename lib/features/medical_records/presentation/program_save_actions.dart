part of 'program_controller.dart';

mixin _ProgramSaveActions on _$ProgramController {
  AppException? _verifySeniorDoctorPermission();

  /// Saves a program, then finishes tracked attachment uploads.
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
  }) async {
    final permError = _verifySeniorDoctorPermission();
    if (permError != null) return Result.failure(permError);

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      scope: ProgramMutationState.saveScope(patientId, null),
    );
    final repo = ref.read(programRepositoryProvider);

    final result = await repo.createProgram(
      patientId: patientId,
      conditionIds: conditionIds,
      examination: examination,
      imagingNotes: imagingNotes,
      exaggeratingPositions: exaggeratingPositions,
      relievingPositions: relievingPositions,
      notes: notes,
      pendingAttachments: pendingAttachments,
      treatmentPlan: treatmentPlan,
    );

    if (!ref.mounted) return result;

    result.when(
      success: (program) {
        state = state.copyWith(isLoading: false, clearError: true);
        ref.read(patientProgramsProvider(patientId).notifier).addOrUpdateProgram(program);
        if (pendingAttachments != null && pendingAttachments.isNotEmpty) {
          ref.invalidate(patientDocumentsNotifierProvider(patientId));
        }
      },
      failure: (e) {
        state = state.copyWith(isLoading: false, error: e);
        if (e.code == 'program/attachments-pending') {
          ref.invalidate(patientProgramsProvider(patientId));
          ref.invalidate(patientDocumentsNotifierProvider(patientId));
        }
      },
    );

    return result;
  }

  /// Updates a program, then finishes tracked attachment uploads.
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
    final permError = _verifySeniorDoctorPermission();
    if (permError != null) return Result.failure(permError);

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      scope: ProgramMutationState.saveScope(patientId, programId),
    );
    final repo = ref.read(programRepositoryProvider);

    final result = await repo.updateProgram(
      programId: programId,
      patientId: patientId,
      conditionIds: conditionIds,
      examination: examination,
      imagingNotes: imagingNotes,
      exaggeratingPositions: exaggeratingPositions,
      relievingPositions: relievingPositions,
      notes: notes,
      status: status,
      pendingAttachments: pendingAttachments,
      removedDocumentIds: removedDocumentIds,
      treatmentPlan: treatmentPlan,
    );

    if (!ref.mounted) return result;

    result.when(
      success: (program) {
        state = state.copyWith(isLoading: false, clearError: true);
        ref.read(patientProgramsProvider(patientId).notifier).addOrUpdateProgram(program);
        ref.invalidate(programDetailProvider(programId));
        if (removedDocumentIds.isNotEmpty ||
            (pendingAttachments != null && pendingAttachments.isNotEmpty)) {
          ref.invalidate(patientDocumentsNotifierProvider(patientId));
        }
      },
      failure: (e) {
        state = state.copyWith(isLoading: false, error: e);
        if (e.code == 'program/attachments-pending') {
          ref.invalidate(patientProgramsProvider(patientId));
          ref.invalidate(patientDocumentsNotifierProvider(patientId));
        }
      },
    );

    return result;
  }
}
