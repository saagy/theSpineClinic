import 'dart:async';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'workspace_data.dart';
import 'workspace_document_repository.dart';

class DeferredDocumentRepository extends WorkspaceDocumentRepository {
  final rows = [
    for (int i = 0; i < 3; i++)
      PatientDocument(
        id: 'doc-$i',
        patientId: workspacePatient.id,
        programId: workspacePrograms.first.id,
        fileName: 'Scan $i.pdf',
        fileUrl: 'private/doc-$i',
        uploadedAt: DateTime(2026, 10, 31 - i),
      ),
  ];
  final deletions = <String, Completer<Result<void>>>{};
  final deleteCalls = <String>[];
  Completer<Result<List<PatientDocument>>>? nextFetch;

  @override
  Future<Result<List<PatientDocument>>> fetchDocuments(String patientId) async {
    final gate = nextFetch;
    nextFetch = null;
    return gate == null ? Result.success([...rows]) : gate.future;
  }

  @override
  Future<Result<void>> deleteDocument({required String documentId}) async {
    deleteCalls.add(documentId);
    final gate = Completer<Result<void>>();
    deletions[documentId] = gate;
    final result = await gate.future;
    if (result.isSuccess) rows.removeWhere((doc) => doc.id == documentId);
    return result;
  }

  @override
  Future<Result<PatientDocument>> renameDocument({
    required String documentId,
    required String fileName,
  }) async {
    final index = rows.indexWhere((doc) => doc.id == documentId);
    rows[index] = rows[index].copyWith(fileName: fileName);
    return Result.success(rows[index]);
  }
}
