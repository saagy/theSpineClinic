import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';

class WorkspaceUploadButton extends ConsumerStatefulWidget {
  const WorkspaceUploadButton({
    super.key,
    required this.patientId,
    this.iconOnly = false,
  });

  final String patientId;
  final bool iconOnly;

  @override
  ConsumerState<WorkspaceUploadButton> createState() => _UploadState();
}

class _UploadState extends ConsumerState<WorkspaceUploadButton> {
  bool _uploading = false;

  Future<void> _upload() async {
    if (_uploading || ref.read(currentUserProvider).value?.isActive != true) return;
    setState(() => _uploading = true);
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        withData: true,
      );
      if (!mounted || picked == null || picked.files.isEmpty) return;
      final file = picked.files.single;
      final bytes = file.bytes;
      if (bytes == null) throw StateError(AppStrings.errorUnknown);
      final result = await ref
          .read(patientDocumentsNotifierProvider(widget.patientId).notifier)
          .uploadDocument(fileName: file.name, fileBytes: bytes);
      if (!mounted) return;
      result.when(
        success: (_) => AppSnackbar.show(context, message: AppStrings.documentUploaded),
        failure: (e) => AppSnackbar.show(
          context,
          message: AppStrings.fromKey(e.userMessageKey),
          variant: AppSnackbarVariant.error,
        ),
      );
    } catch (_) {
      if (mounted) {
        AppSnackbar.show(context, message: AppStrings.errorUnknown, variant: AppSnackbarVariant.error);
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (widget.iconOnly) {
      return IconButton.filled(
        onPressed: _uploading ? null : _upload,
        tooltip: AppStrings.addDocument,
        icon: _uploading
            ? SizedBox(
                width: AppSizes.iconSmall,
                height: AppSizes.iconSmall,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.onPrimary,
                ),
              )
            : const Icon(Icons.add, size: AppSizes.iconSmall),
        style: IconButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          disabledBackgroundColor: cs.primary.withAlpha(160),
          disabledForegroundColor: cs.onPrimary.withAlpha(200),
          minimumSize: const Size(AppSizes.tappableMin, AppSizes.buttonHeightSmall),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r8)),
        ),
      );
    }
    return FilledButton.icon(
      onPressed: _uploading ? null : _upload,
      icon: _uploading
          ? SizedBox(
              width: AppSizes.iconSmall,
              height: AppSizes.iconSmall,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: cs.onPrimary,
              ),
            )
          : const Icon(Icons.add, size: AppSizes.iconSmall),
      label: Text(
        _uploading ? AppStrings.loading : AppStrings.addDocument,
        style: AppTextStyles.captionBold,
      ),
      style: FilledButton.styleFrom(
        minimumSize: const Size(AppSizes.tappableMin, AppSizes.buttonHeightSmall),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r8)),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p12),
      ),
    );
  }
}
