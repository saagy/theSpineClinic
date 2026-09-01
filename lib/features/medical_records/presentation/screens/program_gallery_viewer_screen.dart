import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/utils/file_display_helper.dart';
import 'package:spine_clinic_app/core/utils/viewer_navigation_helper.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/gallery_page_indicator.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/image_viewer_view.dart';
import 'package:spine_clinic_app/shared/widgets/pdf_viewer_view.dart';

class ProgramGalleryViewerScreen extends StatefulWidget {
  const ProgramGalleryViewerScreen({
    super.key,
    required this.documents,
    this.initialIndex = 0,
    this.title = AppStrings.imagingAttachments,
    this.fallbackLocation,
  });

  final List<PatientDocument> documents;
  final int initialIndex;
  final String title;
  final String? fallbackLocation;

  @override
  State<ProgramGalleryViewerScreen> createState() =>
      _ProgramGalleryViewerScreenState();

  static void open(
    BuildContext context, {
    required List<PatientDocument> documents,
    int initialIndex = 0,
    String title = AppStrings.imagingAttachments,
    String? patientId,
    String? programId,
  }) {
    if (documents.isEmpty) return;
    final router = GoRouter.maybeOf(context);
    if (patientId != null && programId != null && router != null) {
      router.push(AppRoutes.programGalleryLocation(patientId: patientId, programId: programId, initialIndex: initialIndex));
    } else {
      Navigator.of(context, rootNavigator: true).push(PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => ProgramGalleryViewerScreen(documents: documents, initialIndex: initialIndex, title: title),
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 150),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      ));
    }
  }
}

class _ProgramGalleryViewerScreenState
    extends State<ProgramGalleryViewerScreen> {
  late final PageController _pageController;
  late int _currentIndex;

  void _close() =>
      closeViewer(context, fallbackLocation: widget.fallbackLocation);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.documents.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, widget.documents.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _stepPage(int delta) {
    final target = _currentIndex + delta;
    if (target >= 0 && target < widget.documents.length) {
      _pageController.animateToPage(
        target,
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
            onPressed: _close,
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
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _stepPage(-1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _stepPage(1),
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
              onPressed: _close,
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
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: widget.documents.length,
                    onPageChanged: (i) => setState(() => _currentIndex = i),
                    itemBuilder: (_, index) {
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
