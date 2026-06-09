import 'file_opener_helper_stub.dart'
    if (dart.library.html) 'file_opener_helper_web.dart'
    if (dart.library.io) 'file_opener_helper_mobile.dart';

/// Helper class to open documents across Web and Mobile/Desktop.
class FileOpenerHelper {
  /// Opens a document by its Supabase storage URL and filename.
  static Future<void> openFile(String url, String filename) {
    return openFileImpl(url, filename);
  }
}
