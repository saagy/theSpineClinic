import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import '../document_upload_controller.dart';

class WorkspaceUploadButton extends ConsumerStatefulWidget {
  const WorkspaceUploadButton({super.key, required this.patientId, this.iconOnly = false});
  final String patientId;
  final bool iconOnly;
  @override
  ConsumerState<WorkspaceUploadButton> createState() => _UploadState();
}

class _UploadState extends ConsumerState<WorkspaceUploadButton> {
  bool _isPicking = false;

  Future<void> _upload() async {
    if (_isPicking || ref.read(currentUserProvider).value?.isActive != true) return;
    setState(() => _isPicking = true);
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        withData: true,
      );
      if (!mounted) return;
      setState(() => _isPicking = false);
      if (picked == null || picked.files.isEmpty) return;
      final result = await ref
          .read(documentUploadControllerProvider(widget.patientId).notifier)
          .uploadFiles(picked.files);
      if (mounted && result.isSuccess) {
        AppSnackbar.show(context, message: AppStrings.documentUploaded);
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.show(
          context,
          message: AppStrings.errorUnknown,
          variant: AppSnackbarVariant.error,
        );
      }
    } finally {
      if (mounted && _isPicking) setState(() => _isPicking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final upload = ref.watch(documentUploadControllerProvider(widget.patientId));
    final canUpload =
        !_isPicking && upload.canPick && ref.watch(currentUserProvider).value?.isActive == true;
    final label = upload.isLoading ? AppStrings.uploading : AppStrings.addDocument;
    final icon = Icon(
      upload.isLoading ? Icons.upload_outlined : Icons.add,
      size: AppSizes.iconSmall,
    );
    if (widget.iconOnly) {
      return IconButton.filled(
        onPressed: canUpload ? _upload : null,
        tooltip: label,
        icon: icon,
        style: IconButton.styleFrom(
          minimumSize: const Size(AppSizes.tappableMin, AppSizes.buttonHeightSmall),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r8)),
        ),
      );
    }
    return FilledButton.icon(
      onPressed: canUpload ? _upload : null,
      icon: icon,
      label: Text(label, style: AppTextStyles.captionBold),
      style: FilledButton.styleFrom(
        minimumSize: const Size(AppSizes.tappableMin, AppSizes.buttonHeightSmall),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r8)),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p12),
      ),
    );
  }
}
