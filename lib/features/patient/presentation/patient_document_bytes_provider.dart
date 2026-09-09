import 'dart:typed_data';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';

part 'patient_document_bytes_provider.g.dart';

/// Private R2/Supabase keys are resolved by the repository, never Image.network.
@riverpod
Future<Uint8List> patientDocumentBytes(Ref ref, PatientDocument document) async {
  final repo = ref.watch(patientDocumentsRepositoryProvider);
  if (document.thumbnailUrl?.isNotEmpty == true) {
    final thumbnail = await repo.downloadDocumentBytes(
      fileUrl: document.thumbnailUrl!,
      fileName: document.fileName,
    );
    final bytes = thumbnail.when(success: (bytes) => bytes, failure: (_) => null);
    if (bytes != null && bytes.isNotEmpty) return bytes;
  }
  final original = await repo.downloadDocumentBytes(fileUrl: document.fileUrl, fileName: document.fileName);
  return original.when(success: (bytes) => bytes, failure: (error) => throw error);
}
