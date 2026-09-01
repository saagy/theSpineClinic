/// Storage folder cleanup for patient documents in Cloudflare R2.
library;

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';

/// Deletes every object under `{patientId}/` in Cloudflare R2
/// using the authenticated Edge Function.
///
/// Returns success when folder objects are deleted.
Future<Result<void>> deletePatientStorageFolderImpl(
  SupabaseService service,
  String patientId,
) async {
  try {
    await service.invokeFunction(
      'document-storage',
      body: {
        'action': 'delete-patient-folder',
        'patientId': patientId,
      },
    );
    return const Result.success(null);
  } on Exception catch (e) {
    return Result.failure(AppException.fromSupabaseException(e));
  }
}
