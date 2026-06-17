import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/file_opener_helper.dart';
import 'package:spine_clinic_app/features/patient/data/patient_documents_repository.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_file_viewer.dart';
import 'package:spine_clinic_app/shared/widgets/app_file_viewer_stub.dart'
    if (dart.library.html) 'package:spine_clinic_app/shared/widgets/app_file_viewer_web.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/data_list_tile.dart';

/// Renders a single document item. Shows image thumbnail or PDF icon
/// with open/delete actions. Open and delete track their own loading
/// state so the UI never appears stuck.
class PatientDocumentItem extends ConsumerStatefulWidget {
  /// Creates a [PatientDocumentItem].
  const PatientDocumentItem({super.key, required this.doc});
  final PatientDocument doc;

  @override
  ConsumerState<PatientDocumentItem> createState() =>
      _PatientDocumentItemState();
}

class _PatientDocumentItemState extends ConsumerState<PatientDocumentItem> {
  bool _isOpening = false;
  bool _isDeleting = false;

  Future<void> _handleOpen() async {
    if (_isOpening) return;
    setState(() => _isOpening = true);
    try {
      if (kIsWeb) {
        final String? signedUrl =
            await generateSignedUrlForWeb(widget.doc.fileUrl);
        if (signedUrl == null) {
          throw Exception('Could not open this file.');
        }
        if (!mounted) return;
        final String ext = p.extension(widget.doc.fileName).toLowerCase();
        showAppFileViewer(
          context,
          signedUrl: signedUrl,
          fileName: widget.doc.fileName,
          isImage: ext == '.png' || ext == '.jpg' || ext == '.jpeg',
          isPdf: ext == '.pdf',
        );
      } else {
        await FileOpenerHelper.openFile(
            widget.doc.fileUrl, widget.doc.fileName);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, message: '$e',
            variant: AppSnackbarVariant.error);
      }
    } finally {
      if (mounted) setState(() => _isOpening = false);
    }
  }

  Future<void> _handleDelete(WidgetRef ref) async {
    if (_isDeleting) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: AppStrings.deleteDocumentTitle,
        message: AppStrings.confirmDeleteDocument,
        confirmLabel: AppStrings.delete,
        cancelLabel: AppStrings.cancel,
        isDestructive: true,
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _isDeleting = true);
    final result = await ref
        .read(patientDocumentsNotifierProvider(widget.doc.patientId).notifier)
        .deleteDocument(widget.doc);
    if (!mounted) return;
    setState(() => _isDeleting = false);
    result.when(
      success: (_) => AppSnackbar.show(context,
          message: AppStrings.documentDeleted,
          variant: AppSnackbarVariant.success),
      failure: (error) => AppSnackbar.show(context,
          message: AppStrings.fromKey(error.userMessageKey),
          variant: AppSnackbarVariant.error),
    );
  }

  Future<Uint8List> _loadImageBytes(WidgetRef ref) async {
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

  @override
  Widget build(BuildContext context) {
    final String ext = p.extension(widget.doc.fileName).toLowerCase();
    final bool isImage = ext == '.png' || ext == '.jpg' || ext == '.jpeg';
    final String dateStr = widget.doc.uploadedAt.toIso8601String().split('T')[0];

    final Widget openButton = _isOpening
        ? const SizedBox(
            width: AppSizes.iconDefault,
            height: AppSizes.iconDefault,
            child: CircularProgressIndicator(
                strokeWidth: AppSizes.strokeWidthThin,
                color: AppColors.primary),
          )
        : IconButton(
            icon: const Icon(Icons.open_in_new_rounded,
                color: AppColors.primary),
            tooltip: AppStrings.openTooltip,
            onPressed: _isDeleting ? null : _handleOpen,
          );

    final Widget deleteButton = _isDeleting
        ? const SizedBox(
            width: AppSizes.iconDefault,
            height: AppSizes.iconDefault,
            child: CircularProgressIndicator(
                strokeWidth: AppSizes.strokeWidthThin,
                color: AppColors.error),
          )
        : IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.error),
            onPressed: _isOpening ? null : () => _handleDelete(ref),
          );

    final trailingButtons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [openButton, deleteButton],
    );

    if (isImage) {
      return Container(
        margin: const EdgeInsets.symmetric(
            horizontal: AppSizes.p16, vertical: AppSizes.p8),
        padding: const EdgeInsets.all(AppSizes.p12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSizes.borderRadiusCard,
          border: Border.all(color: AppColors.border),
          boxShadow: const [AppColors.cardShadow],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.all(Radius.circular(AppSizes.r4)),
              child: Container(
                width: 80,
                height: 80,
                color: AppColors.background,
                child: FutureBuilder<Uint8List>(
                  future: _loadImageBytes(ref),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: SizedBox(
                              width: AppSizes.thumbnailDefault,
                              height: AppSizes.thumbnailDefault,
                              child: CircularProgressIndicator(
                                  strokeWidth:
                                      AppSizes.strokeWidthThin)));
                    }
                    if (snapshot.hasError) {
                      return Container(
                          color: AppColors.errorBg,
                          child: const Icon(Icons.broken_image_outlined,
                              color: AppColors.error,
                              size: AppSizes.iconLarge));
                    }
                    return Image.memory(snapshot.data!,
                        fit: BoxFit.cover, cacheWidth: 150);
                  },
                ),
              ),
            ),
            const SizedBox(width: AppSizes.p16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.doc.fileName,
                      style: AppTextStyles.bodyBold
                          .copyWith(color: AppColors.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: AppSizes.p4),
                  Text(dateStr, style: AppTextStyles.bodySecondary),
                ],
              ),
            ),
            trailingButtons,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p16, vertical: AppSizes.p4),
      child: DataListTile(
        title: widget.doc.fileName,
        subtitle: dateStr,
        leading: const Icon(Icons.picture_as_pdf_outlined,
            color: AppColors.error),
        trailing: trailingButtons,
      ),
    );
  }
}
