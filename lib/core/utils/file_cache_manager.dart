import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to handle client-side caching of documents fetched from Supabase URLs.
class FileCacheManager {
  FileCacheManager._();

  /// Singleton instance of [FileCacheManager].
  static final FileCacheManager instance = FileCacheManager._();

  /// Gets the local file path for a given Supabase file URL and name.
  Future<String> getLocalFilePath(String url, String filename) async {
    final Directory docDir = await getApplicationDocumentsDirectory();
    final Directory cacheDir = Directory(p.join(docDir.path, 'document_cache'));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    // Sanitize the filename to remove invalid filesystem characters
    final String sanitizedName = filename.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    
    // Combine a hash of the url to ensure uniqueness of files with similar names
    final String uniqueName = '${url.hashCode}_$sanitizedName';
    return p.join(cacheDir.path, uniqueName);
  }

  /// Fetches a file from local cache or downloads it from Supabase if not present.
  Future<File> getFile(String url, String filename) async {
    final String localPath = await getLocalFilePath(url, filename);
    final File file = File(localPath);

    if (await file.exists()) {
      return file;
    }

    // Extract relative storage path from the public/private url
    // URL format: .../patient-documents/patientId/filename
    final String key = 'patient-documents/';
    final int index = url.indexOf(key);
    final String storagePath = index != -1
        ? Uri.decodeComponent(url.substring(index + key.length))
        : '';

    if (storagePath.isEmpty) {
      throw Exception('Invalid document URL format: $url');
    }

    try {
      final Uint8List bytes = await Supabase.instance.client.storage
          .from('patient-documents')
          .download(storagePath);

      await file.writeAsBytes(bytes);
      return file;
    } on Exception catch (e) {
      throw Exception('Download failed: $e');
    }
  }
}
