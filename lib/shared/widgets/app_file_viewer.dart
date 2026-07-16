import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/shared/widgets/image_viewer_view.dart';
import 'package:spine_clinic_app/shared/widgets/pdf_viewer_view.dart';

/// Whether [fileName] can be rendered by the in-app viewer.
bool isSupportedAppFile(String fileName) {
  final String extension = p.extension(fileName).toLowerCase();
  return extension == '.pdf' ||
      extension == '.png' ||
      extension == '.jpg' ||
      extension == '.jpeg';
}

/// Full-screen, route-backed viewer for images and PDFs.
class AppFileViewer extends StatelessWidget {
  const AppFileViewer({
    required this.fileUrl,
    required this.fileName,
    super.key,
  });

  final String fileUrl;
  final String fileName;

  @override
  Widget build(BuildContext context) {
    final String extension = p.extension(fileName).toLowerCase();
    final Widget body = switch (extension) {
      '.png' ||
      '.jpg' ||
      '.jpeg' => ImageViewerView(fileUrl: fileUrl, fileName: fileName),
      '.pdf' => PdfViewerView(fileUrl: fileUrl, fileName: fileName),
      _ => const _UnsupportedFileView(),
    };

    return AppFileViewerScaffold(title: fileName, body: body);
  }
}

/// Shared full-screen frame used by viewer loading, error, empty, and data states.
class AppFileViewerScaffold extends StatelessWidget {
  const AppFileViewerScaffold({
    required this.title,
    required this.body,
    super.key,
  });

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        bottom: true,
        child: Column(
          children: [
            _ViewerHeader(title: title),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _ViewerHeader extends StatelessWidget {
  const _ViewerHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      color: colors.surface,
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + AppSizes.p8,
        bottom: AppSizes.p8,
        left: AppSizes.p4,
        right: AppSizes.p12,
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close_rounded, color: colors.onSurface),
            tooltip: AppStrings.close,
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: AppSizes.p4),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.bodyBold.copyWith(color: colors.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnsupportedFileView extends StatelessWidget {
  const _UnsupportedFileView();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p24),
          child: Text(
            AppStrings.unsupportedDocumentType,
            style: AppTextStyles.bodySecondary.copyWith(
              color: colors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
