import 'package:flutter/material.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/shared/widgets/image_viewer_view.dart';
import 'package:spine_clinic_app/shared/widgets/pdf_viewer_view.dart';

/// In-app viewer for images and PDFs.
///
/// Both formats render through Flutter-built widgets loaded from
/// authenticated Supabase bytes (no signed URL, no iframe, no CORS):
///
/// * Images → [ImageViewerView] (InteractiveViewer + Image.memory)
/// * PDFs → [PdfViewerView] (pdfrx → PDFium / WASM PDFium)
///
/// This avoids Safari/iOS PWA popup blockers (compared to opening a new
/// tab) and lets Flutter own rendering so pinch / double-tap zoom and
/// multi-page scroll behave identically on every platform.
void showAppFileViewer(
  BuildContext context, {
  required String fileUrl,
  required String fileName,
  required bool isImage,
  required bool isPdf,
}) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useSafeArea: false,
    builder: (_) => _AppFileViewerDialog(
      fileUrl: fileUrl,
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
    required this.fileUrl,
    required this.fileName,
    required this.isImage,
    required this.isPdf,
  });

  final String fileUrl;
  final String fileName;
  final bool isImage;
  final bool isPdf;

  @override
  State<_AppFileViewerDialog> createState() => _AppFileViewerDialogState();
}

class _AppFileViewerDialogState extends State<_AppFileViewerDialog> {
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
    return ImageViewerView(
      fileUrl: widget.fileUrl,
      fileName: widget.fileName,
    );
  }

  Widget _buildPdfContent() {
    return PdfViewerView(
      fileUrl: widget.fileUrl,
      fileName: widget.fileName,
    );
  }

  Widget _buildBody() {
    if (widget.isImage) {
      return _buildImageContent();
    }
    if (widget.isPdf) {
      return _buildPdfContent();
    }
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      color: AppColors.background,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Text(
          'This file type is not supported for in-app viewing.',
          style: AppTextStyles.bodySecondary.copyWith(color: cs.onSurface),
          textAlign: TextAlign.center,
        ),
      ),
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
