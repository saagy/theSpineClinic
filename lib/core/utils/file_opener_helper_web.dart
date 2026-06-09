// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Web implementation using signed URLs and native window.open.
Future<void> openFileImpl(String url, String filename) async {
  final String key = 'patient-documents/';
  final int index = url.indexOf(key);
  final String storagePath = index != -1
      ? Uri.decodeComponent(url.substring(index + key.length))
      : '';

  if (storagePath.isEmpty) {
    throw Exception('Invalid URL format for document: $url');
  }

  try {
    // Generate a temporary signed URL valid for 60 seconds
    final String signedUrl = await Supabase.instance.client.storage
        .from('patient-documents')
        .createSignedUrl(storagePath, 60);

    // Open signed URL to trigger download/view in browser
    html.window.open(signedUrl, '_blank');
  } catch (e) {
    throw Exception('Web opening failed: $e');
  }
}
