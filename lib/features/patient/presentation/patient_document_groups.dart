/// Derived providers that combine patient documents with their programs.
///
/// Used by the Documents tab to render program-linked docs as folder tiles.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_programs_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';

part 'patient_document_groups.g.dart';

/// One folder tile in the documents tab.
class ProgramDocumentGroup {
  const ProgramDocumentGroup({
    required this.program,
    required this.documents,
  });

  /// The owning program. May be `null` if the program record was deleted
  /// while a document still references its id; in that case the folder
  /// surfaces a generic label.
  final PatientProgram? program;

  /// All documents attached to this program for the patient.
  final List<PatientDocument> documents;

  int get count => documents.length;
}

/// Resolves patient documents into [ProgramDocumentGroup]s.
///
/// Folders are ordered by program `createdAt` descending. Standalone
/// documents (no `programId`) are returned separately so the caller can
/// render them as ordinary doc tiles.
@riverpod
Future<DocumentGroups> patientDocumentGroups(
  Ref ref,
  String patientId,
) async {
  final docs = await ref.watch(
    patientDocumentsNotifierProvider(patientId).future,
  );
  final programsAsync = ref.watch(patientProgramsProvider(patientId));

  final programsById = <String, PatientProgram>{};
  for (final p in programsAsync.value ?? const <PatientProgram>[]) {
    programsById[p.id] = p;
  }

  final byProgram = <String, List<PatientDocument>>{};
  final standalone = <PatientDocument>[];
  for (final doc in docs) {
    final pid = doc.programId;
    if (pid == null || pid.isEmpty) {
      standalone.add(doc);
    } else {
      byProgram.putIfAbsent(pid, () => []).add(doc);
    }
  }

  final folders = byProgram.entries.map((entry) {
    final docs = List<PatientDocument>.from(entry.value)
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    return ProgramDocumentGroup(
      program: programsById[entry.key],
      documents: docs,
    );
  }).toList()
    ..sort((a, b) {
      final ad = a.program?.createdAt;
      final bd = b.program?.createdAt;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });

  standalone.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

  return DocumentGroups(folders: folders, standalone: standalone);
}

/// Bundles the program's docs with the unlinked docs for one patient.
class DocumentGroups {
  const DocumentGroups({required this.folders, required this.standalone});

  final List<ProgramDocumentGroup> folders;
  final List<PatientDocument> standalone;

  bool get isEmpty => folders.isEmpty && standalone.isEmpty;
}
