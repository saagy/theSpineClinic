import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import 'package:spine_clinic_app/shared/widgets/document_bytes_loader.dart';

/// In-app PDF renderer backed by pdfrx (PDFium on native, WASM PDFium on
/// web).
///
/// Bytes are loaded via [DocumentBytesLoader] which uses the authenticated
/// Supabase client, so this works on private buckets without a signed URL
/// ceremony and without CORS on web. pdfrx provides pinch / double-tap
/// zoom and continuous multi-page scroll out of the box.
class PdfViewerView extends StatelessWidget {
  const PdfViewerView({
    required this.fileUrl,
    required this.fileName,
    super.key,
  });

  final String fileUrl;
  final String fileName;

  @override
  Widget build(BuildContext context) {
    return DocumentBytesLoader(
      fileUrl: fileUrl,
      fileName: fileName,
      builder: (BuildContext context, Uint8List bytes) {
        return PdfViewer.data(
          bytes,
          sourceName: fileName,
          params: const PdfViewerParams(),
        );
      },
    );
  }
}
