import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:spine_clinic_app/shared/widgets/document_bytes_loader.dart';

/// In-app image renderer for PNG / JPG / JPEG patient documents.
///
/// Bytes are loaded via [DocumentBytesLoader], then displayed via
/// `Image.memory` (Flutter-decoded bitmap, no `<img src=…>`, no CORS,
/// no expiry). Wrapped in an [InteractiveViewer] so the user can pinch
/// and double-tap zoom between 0.5× and 4× — the same gesture range
/// the previous `Image.network` path exposed.
///
/// `BoxFit.contain` preserves the prior layout so the image fills
/// without cropping on phone screens.
class ImageViewerView extends StatelessWidget {
  const ImageViewerView({
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
        return InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Center(
            child: Image.memory(bytes, fit: BoxFit.contain),
          ),
        );
      },
    );
  }
}
