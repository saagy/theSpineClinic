/// Storage folder cleanup for the `patient-documents` bucket.
///
/// Splits paginated folder listing + removal out of
/// [PatientDocumentsRepositoryImpl] so the file stays under the 200
/// line limit.
library;

import 'package:supabase_flutter/supabase_flutter.dart' hide StorageException;

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';

/// Deletes every object under `{patientId}/` in the patient-documents
/// bucket using paginated `list()` + batched `remove()` calls.
///
/// Returns success when the folder is empty. Storage layer throws are
/// surfaced as [AppException] via [Result.failure].
Future<Result<void>> deletePatientStorageFolderImpl(String patientId) async {
  const String bucket = 'patient-documents';
  try {
    const int pageSize = 100;
    final SupabaseClient client = Supabase.instance.client;

    int currentOffset = 0;
    final List<String> allPaths = <String>[];
    while (true) {
      final List<FileObject> page = await client.storage.from(bucket).list(
            path: patientId,
            searchOptions: SearchOptions(
              limit: pageSize,
              offset: currentOffset,
            ),
          );
      for (final FileObject obj in page) {
        allPaths.add('$patientId/${obj.name}');
      }
      if (page.length < pageSize) break;
      currentOffset += page.length;
    }
    if (allPaths.isEmpty) return const Result.success(null);

    // Supabase remove() accepts up to 1000 entries per call.
    for (int i = 0; i < allPaths.length; i += 1000) {
      final int end = i + 1000 > allPaths.length ? allPaths.length : i + 1000;
      await client.storage.from(bucket).remove(allPaths.sublist(i, end));
    }
    return const Result.success(null);
  } on StorageException catch (e) {
    return Result.failure(AppException.fromSupabaseException(e));
  } on Exception catch (e) {
    return Result.failure(AppException.fromSupabaseException(e));
  }
}
