import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/patient/data/patient_document_storage.dart';

/// Mobile/desktop implementation that downloads a document from
/// Cloudflare R2 (or legacy Supabase storage) to a temp file and opens it via the platform's
/// native viewer.
Future<void> openFileImpl(String url, String filename) async {
  final String? storagePath = patientDocumentStoragePath(url);
  if (storagePath == null || storagePath.isEmpty) {
    throw Exception('Invalid document URL format: $url');
  }

  Uint8List? bytes;

  // Check if legacy Supabase storage URL
  final bool isLegacySupabase = url.contains('supabase.co/storage') ||
      url.contains('/storage/v1/object');
  if (isLegacySupabase) {
    try {
      bytes = await Supabase.instance.client.storage
          .from('patient-documents')
          .download(storagePath);
    } catch (_) {}
  }

  if (bytes == null) {
    final FunctionResponse fnRes = await SupabaseService.instance.invokeFunction(
      'document-storage',
      body: {'action': 'get-download-url', 'objectKey': storagePath},
    );
    final data = fnRes.data as Map<String, dynamic>;
    final String downloadUrl = data['downloadUrl'] as String;

    final http.Response getRes = await http.get(Uri.parse(downloadUrl));
    if (getRes.statusCode >= 200 && getRes.statusCode < 300) {
      bytes = getRes.bodyBytes;
    } else {
      // Fallback to Supabase storage
      try {
        bytes = await Supabase.instance.client.storage
            .from('patient-documents')
            .download(storagePath);
      } catch (_) {
        throw Exception(
            'Failed to download document from storage (HTTP ${getRes.statusCode}).');
      }
    }
  }

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
