library;

import 'package:path/path.dart' as p;

/// Utility methods to sanitize raw filenames and extract clean metadata for display.
abstract final class FileDisplayHelper {
  /// Strips Unix timestamps (e.g. `1780936664913_`) or UUID prefixes from a filename.
  static String sanitizeFileName(String rawName) {
    final trimmed = rawName.trim();
    if (trimmed.isEmpty) return 'Document';

    // Extract basename if full path was passed
    final base = p.basename(trimmed);

    // Regex matching timestamp prefixes like `1780936664913_`
    final timestampRegex = RegExp(r'^\d{10,16}_');
    if (timestampRegex.hasMatch(base)) {
      return base.replaceFirst(timestampRegex, '');
    }

    // Regex matching UUID prefixes like `d41d8cd9-8f00-4b11-b0e6-5272a0f8b1c4_`
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}_',
    );
    if (uuidRegex.hasMatch(base)) {
      return base.replaceFirst(uuidRegex, '');
    }

    return base;
  }

  /// Returns whether the given filename represents a PDF document.
  static bool isPdf(String fileName) {
    return p.extension(fileName).toLowerCase() == '.pdf';
  }

  /// Returns whether the given filename represents a supported image format.
  static bool isImage(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    return ext == '.png' ||
        ext == '.jpg' ||
        ext == '.jpeg' ||
        ext == '.webp' ||
        ext == '.bmp';
  }

  /// Returns the uppercase file extension without the leading dot (e.g. 'PNG', 'PDF').
  static String getExtensionBadge(String fileName) {
    final ext = p.extension(fileName).toLowerCase().replaceAll('.', '');
    if (ext.isEmpty) return isPdf(fileName) ? 'PDF' : 'FILE';
    return ext.toUpperCase();
  }
}
