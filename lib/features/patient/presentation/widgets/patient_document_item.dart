/// Grid card for a single patient document.
///
/// Shows image thumbnail (cached in initState) or PDF icon.
/// Tap card to open, delete icon in top-right corner for admins.
///
/// Bug fix: image Future cached in initState, not recreated in build.
/// Rule 15/16 — colours via Theme.of(context).colorScheme.
library;

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/utils/file_opener_helper.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_documents_repository.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_file_viewer.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';

class PatientDocumentItem extends ConsumerStatefulWidget {
  const PatientDocumentItem({super.key, required this.doc});
  final PatientDocument doc;

  @override
  ConsumerState<PatientDocumentItem> createState() =>
      _PatientDocumentItemState();
}

class _PatientDocumentItemState extends ConsumerState<PatientDocumentItem> {
  bool _isOpening = false;
  bool _isDeleting = false;
  bool _isConfirmingDelete = false;

  late final Future<Uint8List>? _imageFuture;

  @override
  void initState() {
    super.initState();
    final String ext = p.extension(widget.doc.fileName).toLowerCase();
    final bool isImage = ext == '.png' || ext == '.jpg' || ext == '.jpeg';
    _imageFuture = isImage ? _loadImageBytes() : null;
  }

  Future<Uint8List> _loadImageBytes() async {
    final PatientDocumentsRepository repo =
        ref.read(patientDocumentsRepositoryProvider);
    final result = await repo.downloadDocumentBytes(
      fileUrl: widget.doc.fileUrl,
      fileName: widget.doc.fileName,
    );
    return result.when(
      success: (bytes) => bytes,
      failure: (error) => throw error,
    );
  }

  Future<void> _handleOpen() async {
    if (_isOpening) return;
    setState(() => _isOpening = true);
    try {
      final String ext = p.extension(widget.doc.fileName).toLowerCase();
      final bool isPdf = ext == '.pdf';
      final bool isImage = ext == '.png' || ext == '.jpg' || ext == '.jpeg';
      if (isPdf || isImage) {
        showAppFileViewer(context,
            fileUrl: widget.doc.fileUrl,
            fileName: widget.doc.fileName,
            isImage: isImage,
            isPdf: isPdf);
      } else {
        await FileOpenerHelper.openFile(widget.doc.fileUrl, widget.doc.fileName);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context,
            message: AppStrings.errorUnknown, variant: AppSnackbarVariant.error);
      }
    } finally {
      if (mounted) setState(() => _isOpening = false);
    }
  }

  Future<void> _handleDelete() async {
    if (_isDeleting || _isConfirmingDelete) return;
    setState(() => _isConfirmingDelete = true);
    bool? confirm;
    try {
      if (!mounted) return;
      confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => const ConfirmationDialog(
          title: AppStrings.deleteDocumentTitle,
          message: AppStrings.confirmDeleteDocument,
          confirmLabel: AppStrings.delete,
          cancelLabel: AppStrings.cancel,
          isDestructive: true,
        ),
      );
    } finally {
      if (mounted) setState(() => _isConfirmingDelete = false);
    }
    if (confirm != true || !mounted) return;
    if (_isDeleting) return;

    setState(() => _isDeleting = true);
    try {
      final Result<void> result = await ref
          .read(patientDocumentsNotifierProvider(widget.doc.patientId).notifier)
          .deleteDocument(widget.doc);
      if (!mounted) return;
      result.when(
        success: (_) => AppSnackbar.show(context,
            message: AppStrings.documentDeleted,
            variant: AppSnackbarVariant.success),
        failure: (error) => AppSnackbar.show(context,
            message: AppStrings.fromKey(error.userMessageKey),
            variant: AppSnackbarVariant.error),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final String dateStr =
        widget.doc.uploadedAt.toIso8601String().split('T')[0];

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSizes.r16),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.r16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isDeleting ? null : _handleOpen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildPreview(cs),
                      if (_isOpening)
                        Container(
                          color: cs.scrim.withAlpha(100),
                          child: Center(
                            child: SizedBox(
                              width: AppSizes.iconDefault,
                              height: AppSizes.iconDefault,
                              child: CircularProgressIndicator(
                                strokeWidth: AppSizes.strokeWidthThin,
                                color: cs.primary,
                              ),
                            ),
                          ),
                        ),
                      if (_isDeleting)
                        Container(
                          color: cs.scrim.withAlpha(100),
                          child: Center(
                            child: SizedBox(
                              width: AppSizes.iconDefault,
                              height: AppSizes.iconDefault,
                              child: CircularProgressIndicator(
                                strokeWidth: AppSizes.strokeWidthThin,
                                color: cs.error,
                              ),
                            ),
                          ),
                        )
                      else
                        Positioned(
                          top: AppSizes.p8,
                          right: AppSizes.p8,
                          child: GestureDetector(
                            onTap: _isOpening ? null : _handleDelete,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: cs.surface,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: cs.shadow.withAlpha(40),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                color: cs.error,
                                size: AppSizes.iconSmall,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSizes.p12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.doc.fileName,
                        style: AppTextStyles.captionMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSizes.p2),
                      Text(dateStr, style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(ColorScheme cs) {
    if (_imageFuture != null) {
      return FutureBuilder<Uint8List>(
        future: _imageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              color: cs.surfaceContainerHighest,
              child: const Center(
                child: SizedBox(
                  width: AppSizes.iconDefault,
                  height: AppSizes.iconDefault,
                  child: CircularProgressIndicator(strokeWidth: AppSizes.strokeWidthThin),
                ),
              ),
            );
          }
          if (snapshot.hasError) {
            return Container(
              color: cs.errorContainer,
              child: Icon(Icons.broken_image_outlined, color: cs.error, size: AppSizes.iconLarge),
            );
          }
          return Image.memory(snapshot.data!, fit: BoxFit.cover);
        },
      );
    }
    return Container(
      color: cs.surfaceContainerHighest,
      child: Icon(Icons.picture_as_pdf_outlined, color: cs.error, size: AppSizes.iconHero),
    );
  }
}
