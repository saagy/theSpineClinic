import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/record_section.dart';

class WorkspaceUploadButton extends ConsumerStatefulWidget {
  const WorkspaceUploadButton({super.key, required this.patientId});
  final String patientId;
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
  Widget build(BuildContext context) => RecordAddButton(
    onPressed: _uploading ? null : _upload,
    label: _uploading ? AppStrings.loading : AppStrings.addDocument,
  );
}
