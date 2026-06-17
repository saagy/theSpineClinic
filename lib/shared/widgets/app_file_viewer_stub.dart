/// Stub implementation of the PDF content builder for non-web platforms.
///
/// On native mobile the file is opened via [OpenFilex] (see
/// `file_opener_helper_mobile.dart`), so the AppFileViewer's PDF path
/// should never be reached. This stub exists only to satisfy the
/// conditional-import contract.
library;

import 'package:flutter/material.dart';

/// Returns a fallback widget that is never expected to be displayed.
Widget buildPdfContent(String signedUrl, String viewId) {
  return const Center(
    child: Text('PDF viewing is handled by the native file opener.'),
  );
}

/// On native this is never called — files are opened via [OpenFilex].
/// Returns `null` to satisfy the conditional-import contract.
Future<String?> generateSignedUrlForWeb(String fileUrl) async => null;
