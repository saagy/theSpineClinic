import 'dart:typed_data';
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
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/data_list_tile.dart';

/// Renders a single document item. Shows image thumbnail or PDF icon with download/delete actions.
class PatientDocumentItem extends ConsumerWidget {
  /// Creates a [PatientDocumentItem].
  const PatientDocumentItem({super.key, required this.doc});
  final PatientDocument doc;

  Future<void> _handleOpen(BuildContext context) async {
    AppSnackbar.show(
      context,
      message: 'Opening document...',
      variant: AppSnackbarVariant.info,
    );
    try {
      await FileOpenerHelper.openFile(doc.fileUrl, doc.fileName);
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.show(
          context,
          message: 'Could not open document: $e',
          variant: AppSnackbarVariant.error,
        );
      }
    }
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => const ConfirmationDialog(
        title: 'Delete Document',
        message: 'Are you sure you want to permanently delete this document?',
        confirmLabel: 'Delete',
        cancelLabel: 'Cancel',
        isDestructive: true,
      ),
    );
    if (confirm != true) return;
    final result = await ref
        .read(patientDocumentsNotifierProvider(doc.patientId).notifier)
        .deleteDocument(doc);
    if (!context.mounted) return;
    result.when(
      success: (_) => AppSnackbar.show(context, message: 'Document deleted successfully.', variant: AppSnackbarVariant.success),
      failure: (error) => AppSnackbar.show(context, message: AppStrings.fromKey(error.userMessageKey), variant: AppSnackbarVariant.error),
    );
  }

  Future<Uint8List> _loadImageBytes(WidgetRef ref) async {
    final PatientDocumentsRepository repo = ref.read(patientDocumentsRepositoryProvider);
    final result = await repo.downloadDocumentBytes(
      fileUrl: doc.fileUrl,
      fileName: doc.fileName,
    );
    return result.when(
      success: (bytes) => bytes,
      failure: (error) => throw error,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String ext = p.extension(doc.fileName).toLowerCase();
    final bool isImage = ext == '.png' || ext == '.jpg' || ext == '.jpeg';
    final String dateStr = doc.uploadedAt.toIso8601String().split('T')[0];

    final trailingButtons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.open_in_new_rounded, color: AppColors.primary),
          tooltip: AppStrings.openTooltip,
          onPressed: () => _handleOpen(context),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
          onPressed: () => _handleDelete(context, ref),
        ),
      ],
    );

    if (isImage) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p8),
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
              borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r4)),
              child: Container(
                width: 80,
                height: 80,
                color: AppColors.background,
                child: FutureBuilder<Uint8List>(
                  future: _loadImageBytes(ref),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: SizedBox(width: AppSizes.thumbnailDefault, height: AppSizes.thumbnailDefault, child: CircularProgressIndicator(strokeWidth: AppSizes.strokeWidthThin)));
                    }
                    if (snapshot.hasError) {
                      return Container(color: AppColors.errorBg, child: const Icon(Icons.broken_image_outlined, color: AppColors.error, size: AppSizes.iconLarge));
                    }
                    return Image.memory(snapshot.data!, fit: BoxFit.cover, cacheWidth: 150);
                  },
                ),
              ),
            ),
            const SizedBox(width: AppSizes.p16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc.fileName, style: AppTextStyles.bodyBold.copyWith(color: AppColors.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p4),
      child: DataListTile(
        title: doc.fileName,
        subtitle: dateStr,
        leading: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.error),
        trailing: trailingButtons,
      ),
    );
  }
}
