// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/patient/data/patient_document_storage.dart';

/// Web implementation using presigned Cloudflare R2 URLs (with legacy fallback).
Future<void> openFileImpl(String url, String filename) async {
  final String? storagePath = patientDocumentStoragePath(url);
  if (storagePath == null || storagePath.isEmpty) {
    throw Exception('Invalid URL format for document: $url');
  }

  try {
    final bool isLegacySupabase = url.contains('supabase.co/storage') ||
        url.contains('/storage/v1/object');

    if (isLegacySupabase) {
      try {
        final String signedUrl = await Supabase.instance.client.storage
            .from('patient-documents')
            .createSignedUrl(storagePath, 60);
        html.window.open(signedUrl, '_blank');
        return;
      } catch (_) {}
    }

    final FunctionResponse fnRes = await SupabaseService.instance.invokeFunction(
      'document-storage',
      body: {'action': 'get-download-url', 'objectKey': storagePath},
    );
    final data = fnRes.data as Map<String, dynamic>;
    final String downloadUrl = data['downloadUrl'] as String;

    html.window.open(downloadUrl, '_blank');
  } catch (e) {
    throw Exception('Web opening failed: $e');
  }
}
