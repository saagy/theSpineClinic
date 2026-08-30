library;

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_repository.dart';

/// Helper to manage atomic storage uploads and compensating deletions for programs.
abstract final class ProgramStorageHelper {
  static const String bucket = 'patient-documents';
  static const int maxBytes = 10 * 1024 * 1024; // 10MB

  /// Uploads all attachments to storage.
  /// If any upload fails, immediately rolls back and cleans up uploaded files.
  static Future<({List<Map<String, dynamic>> payloads, List<String> paths})>
      uploadAttachments({
    required SupabaseService service,
    required String patientId,
    required List<ProgramAttachment> attachments,
  }) async {
    final paths = <String>[];
    final payloads = <Map<String, dynamic>>[];

    try {
      for (final att in attachments) {
        if (att.bytes.length > maxBytes) {
          throw const StorageException(
            code: 'storage/file-too-large',
            message: 'File exceeds 10 MB limit.',
            userMessageKey: 'error_doc_file_too_large',
          );
        }

        final stamp = DateTime.now().millisecondsSinceEpoch.toString();
        final storagePath = '$patientId/${stamp}_${att.fileName}';

        await service.storage(bucket).uploadBinary(storagePath, att.bytes);
        paths.add(storagePath);

        final fileUrl = service.storage(bucket).getPublicUrl(storagePath);
        payloads.add({
          'file_url': fileUrl,
          'file_name': att.fileName,
        });
      }

      return (payloads: payloads, paths: paths);
    } catch (e) {
      await cleanupPaths(service: service, paths: paths);
      rethrow;
    }
  }

  /// Best-effort compensating deletion of uploaded storage paths.
  static Future<void> cleanupPaths({
    required SupabaseService service,
    required List<String> paths,
  }) async {
    if (paths.isEmpty) return;
    try {
      await service.storage(bucket).remove(paths);
    } catch (_) {
      // Best-effort cleanup
    }
  }
}
