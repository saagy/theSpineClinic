/// In-app viewer for images and PDFs — avoids Safari popup blocker and
/// PWA standalone-mode issues by rendering content inside the app instead
/// of calling `window.open`.
///
/// Images → [InteractiveViewer] + [Image.network]. PDFs → `<iframe>` on
/// web, native opener fallback on mobile.
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

import 'app_file_viewer_stub.dart'
    if (dart.library.html) 'app_file_viewer_web.dart';

/// Opens a full-screen dialog that displays [signedUrl] in-app.
void showAppFileViewer(
  BuildContext context, {
  required String signedUrl,
  required String fileName,
  required bool isImage,
  required bool isPdf,
}) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useSafeArea: false,
    builder: (_) => _AppFileViewerDialog(
      signedUrl: signedUrl,
      fileName: fileName,
      isImage: isImage,
      isPdf: isPdf,
    ),
  );
}

// ── Private ──

/// Full-screen dialog rendering the file content.
class _AppFileViewerDialog extends StatefulWidget {
  const _AppFileViewerDialog({
    required this.signedUrl,
    required this.fileName,
    required this.isImage,
    required this.isPdf,
  });

  final String signedUrl;
  final String fileName;
  final bool isImage;
  final bool isPdf;

  @override
  State<_AppFileViewerDialog> createState() => _AppFileViewerDialogState();
}

class _AppFileViewerDialogState extends State<_AppFileViewerDialog> {
  Object? _imageError;

  Widget _buildHeader() {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surface,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSizes.p8,
        bottom: AppSizes.p8,
        left: AppSizes.p4,
        right: AppSizes.p12,
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close_rounded, color: cs.onSurface),
            tooltip: 'Close viewer',
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: AppSizes.p4),
          Expanded(
            child: Text(
              widget.fileName,
              style: AppTextStyles.bodyBold.copyWith(color: cs.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent() {
    final ColorScheme cs = Theme.of(context).colorScheme;

    if (_imageError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined,
                size: AppSizes.iconHero, color: cs.error),
            const SizedBox(height: AppSizes.p16),
            Text('Could not load image',
                style: AppTextStyles.bodySecondary
                    .copyWith(color: cs.error)),
          ],
        ),
      );
    }

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: Image.network(
          widget.signedUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, ImageChunkEvent? progress) {
            if (progress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                    : null,
                color: cs.primary,
              ),
            );
          },
          errorBuilder: (context, error, stack) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _imageError = error);
            });
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildPdfContent() {
    if (kIsWeb) {
      final String viewId =
          'pdf-viewer-${widget.signedUrl.hashCode}';
      return buildPdfContent(widget.signedUrl, viewId);
    }
    // On native this path should not be reached — files open via
    // OpenFilex. Show a clear message just in case.
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Text(
          'PDF files open in your device viewer.',
          style: AppTextStyles.bodyLarge.copyWith(color: cs.onSurface),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (widget.isImage) {
      return _buildImageContent();
    }
    if (widget.isPdf) {
      return _buildPdfContent();
    }
    // Unknown / unsupported type
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Center(
      child: Text('This file type is not supported for in-app viewing.',
          style: AppTextStyles.bodySecondary.copyWith(color: cs.onSurface)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        bottom: true,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }
}
