import 'package:open_filex/open_filex.dart';
import 'package:spine_clinic_app/core/utils/file_cache_manager.dart';

/// Mobile/desktop implementation that resolves the file path from cache and opens it.
Future<void> openFileImpl(String url, String filename) async {
  // Retrieve the file from local cache (downloads if not present)
  final file = await FileCacheManager.instance.getFile(url, filename);

  try {
    // Open the file using the device's native app viewer
    final result = await OpenFilex.open(file.path);
    switch (result.type) {
      case ResultType.done:
        break;
      case ResultType.fileNotFound:
        throw Exception('The document file could not be found locally.');
      case ResultType.noAppToOpen:
        throw Exception('No app installed on this device can open this file type.');
      case ResultType.permissionDenied:
        throw Exception('Permission denied to access or open the document.');
      case ResultType.error:
        throw Exception(result.message.isNotEmpty ? result.message : 'An unknown error occurred.');
    }
  } catch (e) {
    throw Exception('Failed to open document: $e');
  }
}
