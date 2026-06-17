// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

/// Web-specific helpers for the in-app file viewer.
///
/// Provides an IFrame-based PDF renderer via [HtmlElementView] and a
/// utility that generates a short-lived Supabase Storage signed URL.
library;

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Registers an [IFrameElement] as a platform view and returns the
/// corresponding [HtmlElementView] widget.
///
/// [signedUrl] — the full signed URL to display in the iframe.
/// [viewId] — a unique-per-instance string used to register the view
///   factory; must differ for every call site to avoid collisions.
Widget buildPdfContent(String signedUrl, String viewId) {
  // ignore: undefined_prefixed_name
  ui_web.platformViewRegistry.registerViewFactory(viewId, (int _) {
    final iframe = html.IFrameElement()
      ..src = signedUrl
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.border = 'none'
      ..allowFullscreen = true;
    return iframe;
  });
  return HtmlElementView(viewType: viewId);
}

/// Extracts a storage path from a [fileUrl] and returns a 60-second
/// signed URL suitable for `<iframe>` or `Image.network` display.
///
/// Returns `null` when the URL does not contain a parseable storage
/// path (e.g. a public URL from an unknown bucket).
Future<String?> generateSignedUrlForWeb(String fileUrl) async {
  const String key = 'patient-documents/';
  final int index = fileUrl.indexOf(key);
  if (index == -1) return null;
  final String storagePath =
      Uri.decodeComponent(fileUrl.substring(index + key.length));
  if (storagePath.isEmpty) return null;

  final String signedUrl = await Supabase.instance.client.storage
      .from('patient-documents')
      .createSignedUrl(storagePath, 60);
  return signedUrl;
}
