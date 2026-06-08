import 'file_download_helper_stub.dart'
    if (dart.library.html) 'file_download_helper_web.dart'
    if (dart.library.io) 'file_download_helper_mobile.dart';

/// Reusable helper to download files across web and mobile.
class FileDownloadHelper {
  /// Resolves the correct platform implementation and triggers the download.
  static Future<void> downloadFile(String url, String filename) {
    return downloadFileImpl(url, filename);
  }
}
