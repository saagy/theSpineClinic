import 'package:supabase_flutter/supabase_flutter.dart' hide StorageException;

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';

String? patientDocumentStoragePath(String? url) {
  if (url == null) return null;
  const String marker = 'patient-documents/';
  final int index = url.indexOf(marker);
  if (index == -1) return null;
  return Uri.decodeComponent(url.substring(index + marker.length));
}

/// Deletes metadata first, then best-effort linked Storage objects.
Future<Result<void>> deleteStoredPatientDocument({
  required SupabaseService service,
  required String bucket,
  required String documentId,
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
      if (paths.isNotEmpty) {
        try {
          await service.storage(bucket).remove(paths);
          // ignore: unused_result
        } on StorageException {
          // Patient-folder cleanup later removes any orphaned object.
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
