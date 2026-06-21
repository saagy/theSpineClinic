import 'dart:io';
import 'dart:typed_data';

import 'package:open_filex/open_filex.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide StorageException;

/// Mobile/desktop implementation that downloads a document from
/// Supabase Storage to a temp file and opens it via the platform's
/// native viewer.
///
/// No client cache: every open call downloads fresh bytes via the
/// authenticated Supabase client.
Future<void> openFileImpl(String url, String filename) async {
  const String bucket = 'patient-documents';
  final String key = '$bucket/';
  final int index = url.indexOf(key);
  if (index == -1) {
    throw Exception('Invalid document URL format: $url');
  }
  final String storagePath =
      Uri.decodeComponent(url.substring(index + key.length));
  if (storagePath.isEmpty) {
    throw Exception('Invalid document URL format: $url');
  }

  final Uint8List bytes =
      await Supabase.instance.client.storage.from(bucket).download(storagePath);

  final String sanitized =
      filename.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  final File tempFile =
      File('${Directory.systemTemp.path}/$sanitized');
  await tempFile.writeAsBytes(bytes, flush: true);

  try {
    final result = await OpenFilex.open(tempFile.path);
    switch (result.type) {
      case ResultType.done:
        return;
      case ResultType.fileNotFound:
        throw Exception('The downloaded document could not be found.');
      case ResultType.noAppToOpen:
        throw Exception(
            'No app installed on this device can open this file type.');
      case ResultType.permissionDenied:
        throw Exception(
            'Permission denied to access or open the document.');
      case ResultType.error:
        throw Exception(result.message.isNotEmpty
            ? result.message
            : 'An unknown error occurred.');
    }
  } catch (e) {
    throw Exception('Failed to open document: $e');
  }
}
