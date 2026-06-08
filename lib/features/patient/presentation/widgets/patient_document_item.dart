import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/file_cache_manager.dart';
import 'package:spine_clinic_app/core/utils/file_download_helper.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
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

  Future<void> _handleDownload(BuildContext context) async {
    if (kIsWeb) {
      AppSnackbar.show(context, message: 'Downloading file...', variant: AppSnackbarVariant.info);
      try {
        await FileDownloadHelper.downloadFile(doc.fileUrl, doc.fileName);
        if (context.mounted) {
          AppSnackbar.show(context, message: 'Download started in browser.', variant: AppSnackbarVariant.success);
        }
      } catch (e) {
        if (context.mounted) {
          AppSnackbar.show(context, message: 'Download failed: $e', variant: AppSnackbarVariant.error);
        }
      }
      return;
    }

    final cache = FileCacheManager.instance;
    final String localPath = await cache.getLocalFilePath(doc.fileUrl, doc.fileName);
    if (!context.mounted) return;
    final exists = await File(localPath).exists();
    if (!context.mounted) return;
    if (exists) {
      AppSnackbar.show(context, message: 'File loaded from cache: $localPath', variant: AppSnackbarVariant.success);
      return;
    }
    AppSnackbar.show(context, message: 'Downloading file...', variant: AppSnackbarVariant.info);
    try {
      final File cachedFile = await cache.getFile(doc.fileUrl, doc.fileName);
      if (context.mounted) {
        AppSnackbar.show(context, message: 'Saved to cache: ${cachedFile.path}', variant: AppSnackbarVariant.success);
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.show(context, message: 'Download failed: $e', variant: AppSnackbarVariant.error);
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

  Future<Uint8List> _loadImageBytes() async {
    final String key = 'patient-documents/';
    final int index = doc.fileUrl.indexOf(key);
    final String storagePath = index != -1
        ? Uri.decodeComponent(doc.fileUrl.substring(index + key.length))
        : '';
    if (storagePath.isEmpty) {
      throw Exception('Invalid storage path');
    }
    if (kIsWeb) {
      return await Supabase.instance.client.storage
          .from('patient-documents')
          .download(storagePath);
    } else {
      final File file = await FileCacheManager.instance.getFile(doc.fileUrl, doc.fileName);
      return await file.readAsBytes();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final isDoctor = user?.role == UserRole.doctor;
    final String ext = p.extension(doc.fileName).toLowerCase();
    final bool isImage = ext == '.png' || ext == '.jpg' || ext == '.jpeg';
    final String dateStr = doc.uploadedAt.toIso8601String().split('T')[0];

    final trailingButtons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.download_rounded, color: AppColors.primary),
          onPressed: () => _handleDownload(context),
        ),
        if (!isDoctor)
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
                  future: _loadImageBytes(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
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
