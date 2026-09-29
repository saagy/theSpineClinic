import 'package:spine_clinic_app/core/network/supabase_service.dart';

/// Removes storage objects after their database records have been deleted.
abstract final class ProgramStorageHelper {
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
