library;

import 'package:http/http.dart' as http;
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_repository.dart';

/// Helper to manage atomic Cloudflare R2 storage uploads and compensating deletions for programs.
abstract final class ProgramStorageHelper {
  static const int maxBytes = 10 * 1024 * 1024; // 10MB

  /// Uploads all attachments to Cloudflare R2 storage via presigned URLs.
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

        final fnRes = await service.invokeFunction(
          'document-storage',
          body: {
            'action': 'get-upload-url',
            'patientId': patientId,
            'fileName': att.fileName,
          },
        );
        final data = fnRes.data as Map<String, dynamic>;
        final String uploadUrl = data['uploadUrl'] as String;
        final String objectKey = data['objectKey'] as String;
        final String contentType =
            (data['contentType'] as String?) ?? 'application/octet-stream';

        final putRes = await http.put(
          Uri.parse(uploadUrl),
          headers: {'Content-Type': contentType},
          body: att.bytes,
        );

        if (putRes.statusCode < 200 || putRes.statusCode >= 300) {
          throw StorageException(
            code: 'storage/upload-failed',
            message: 'R2 upload failed with HTTP ${putRes.statusCode}',
            userMessageKey: 'error_unknown',
          );
        }

        paths.add(objectKey);
        payloads.add({
          'file_url': objectKey,
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
      await service.invokeFunction(
        'document-storage',
        body: {
          'action': 'delete-objects',
          'objectKeys': paths,
        },
      );
    } catch (_) {
      // Best-effort cleanup per Rule 27
    }
  }
}
