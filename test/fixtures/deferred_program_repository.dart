import 'dart:async';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_repository.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_status.dart';
import 'package:spine_clinic_app/features/medical_records/domain/treatment_plan_input.dart';
import 'deferred_document_repository.dart';
import 'workspace_data.dart';

class DeferredProgramRepository implements ProgramRepository {
  DeferredProgramRepository(this.documents);
  final DeferredDocumentRepository documents;
  final removedRequests = <List<String>>[];
  Completer<Result<PatientProgram>> gate = Completer<Result<PatientProgram>>();

  @override
  Future<Result<List<PatientProgram>>> getProgramsForPatient(String patientId) async =>
      Result.success(workspacePrograms);

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
    removedRequests.add([...removedDocumentIds]);
    final result = await gate.future;
    if (result.isSuccess) documents.rows.removeWhere((doc) => removedDocumentIds.contains(doc.id));
    return result;
  }

  @override
  Object? noSuchMethod(Invocation invocation) => throw UnsupportedError('${invocation.memberName}');
}
