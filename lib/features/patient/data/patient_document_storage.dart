import 'package:supabase_flutter/supabase_flutter.dart' hide StorageException;

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/patient/data/patient_document_cache.dart';

/// Extracts the clean storage object key (e.g. `patientId/stamp_fileName`)
/// from a stored URL or raw key string.
String? patientDocumentStoragePath(String? url) {
  if (url == null || url.trim().isEmpty) return null;
  final String trimmed = url.trim();
  const String marker = 'patient-documents/';
  final int index = trimmed.indexOf(marker);
  if (index != -1) {
    return Uri.decodeComponent(trimmed.substring(index + marker.length));
  }
  // Strip any query parameters if a signed URL was passed
  final int queryIndex = trimmed.indexOf('?');
  final String pathPart =
      queryIndex != -1 ? trimmed.substring(0, queryIndex) : trimmed;
  // If it's a full http/https URL with standard S3/R2 path
  if (pathPart.startsWith('http://') || pathPart.startsWith('https://')) {
    final uri = Uri.tryParse(pathPart);
    if (uri != null && uri.pathSegments.length >= 2) {
      return uri.pathSegments.sublist(uri.pathSegments.length - 2).join('/');
    }
  }
  return Uri.decodeComponent(pathPart);
}

/// Deletes metadata first, then best-effort linked Storage objects from R2.
Future<Result<void>> deleteStoredPatientDocument({
  required SupabaseService service,
  required String documentId,
  PatientDocumentCache? cache,
  String? bucket, // Kept optional for backward compatibility
}) async {
  try {
    final Map<String, dynamic>? row = await service
        .from('patient_documents')
        .select('file_url, thumbnail_url')
        .eq('id', documentId)
        .maybeSingle();
    await service.from('patient_documents').delete().eq('id', documentId);

    if (row != null) {
      final List<String> paths = <String?>[
        patientDocumentStoragePath(row['file_url'] as String?),
        patientDocumentStoragePath(row['thumbnail_url'] as String?),
      ].whereType<String>().where((String path) => path.isNotEmpty).toList();

      for (final String path in paths) {
        cache?.remove(path);
      }

      if (paths.isNotEmpty) {
        try {
          await service.invokeFunction('document-storage', body: {
            'action': 'delete-objects',
            'objectKeys': paths,
          });
        } catch (_) {
          // Best-effort cleanup per Rule 27
        }
      }
    }
    return const Result.success(null);
  } on PostgrestException catch (error) {
    return Result.failure(AppException.fromSupabaseException(error));
  } on Exception catch (error) {
    return Result.failure(AppException.fromSupabaseException(error));
  }
}
