library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/file_display_helper.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/gallery_nav_button.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/gallery_page_indicator.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/image_viewer_view.dart';
import 'package:spine_clinic_app/shared/widgets/pdf_viewer_view.dart';

/// Full-screen lightbox gallery supporting swipe, click arrows, and keyboard navigation.
class ProgramGalleryViewerScreen extends StatefulWidget {
  const ProgramGalleryViewerScreen({
    super.key,
    required this.documents,
    this.initialIndex = 0,
    this.title = AppStrings.imagingAttachments,
  });

  final List<PatientDocument> documents;
  final int initialIndex;
  final String title;

  @override
  State<ProgramGalleryViewerScreen> createState() =>
      _ProgramGalleryViewerScreenState();
}

class _ProgramGalleryViewerScreenState
    extends State<ProgramGalleryViewerScreen> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.documents.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _previousPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextPage() {
    if (_currentIndex < widget.documents.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (widget.documents.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.pop(),
          ),
          title: Text(widget.title),
        ),
        body: const Center(
          child: EmptyState(
            message: AppStrings.noAttachments,
            icon: Icons.image_not_supported_outlined,
          ),
        ),
      );
    }

    final currentDoc = widget.documents[_currentIndex];
    final cleanName = FileDisplayHelper.sanitizeFileName(currentDoc.fileName);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): _previousPage,
        const SingleActivator(LogicalKeyboardKey.arrowRight): _nextPage,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: cs.surface,
          appBar: AppBar(
            backgroundColor: cs.surface,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.close_rounded, color: cs.onSurface),
              tooltip: AppStrings.close,
              onPressed: () => context.pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cleanName,
                  style: AppTextStyles.bodyBold.copyWith(color: cs.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  AppStrings.scanItemIndex(
                    _currentIndex + 1,
                    widget.documents.length,
                  ),
                  style: AppTextStyles.caption.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: widget.documents.length,
                        onPageChanged: (i) => setState(() => _currentIndex = i),
                        itemBuilder: (context, index) {
                          final doc = widget.documents[index];
                          return FileDisplayHelper.isPdf(doc.fileName)
                              ? PdfViewerView(
                                  fileUrl: doc.fileUrl,
                                  fileName: doc.fileName,
                                )
                              : ImageViewerView(
                                  fileUrl: doc.fileUrl,
                                  fileName: doc.fileName,
                                );
                        },
                      ),
                      if (_currentIndex > 0)
                        Positioned(
                          left: AppSizes.p16,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: GalleryNavButton(
                              icon: Icons.chevron_left_rounded,
                              onTap: _previousPage,
                            ),
                          ),
                        ),
                      if (_currentIndex < widget.documents.length - 1)
                        Positioned(
                          right: AppSizes.p16,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: GalleryNavButton(
                              icon: Icons.chevron_right_rounded,
                              onTap: _nextPage,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.documents.length > 1)
                  GalleryPageIndicator(
                    itemCount: widget.documents.length,
                    currentIndex: _currentIndex,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
