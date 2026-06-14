import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_document_item.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

class PatientTabDocuments extends ConsumerStatefulWidget {
  const PatientTabDocuments({super.key, required this.patient});
  final Patient patient;

  @override
  ConsumerState<PatientTabDocuments> createState() =>
      _PatientTabDocumentsState();
}

class _PatientTabDocumentsState extends ConsumerState<PatientTabDocuments> {
  bool _isUploadingLocal = false;

  Future<void> _doUpload(FileType type, {List<String>? allowed}) async {
    final result = await FilePicker.platform.pickFiles(
      type: type, allowedExtensions: allowed, allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    setState(() => _isUploadingLocal = true);
    final uploadResult = await ref
        .read(patientDocumentsNotifierProvider(widget.patient.id).notifier)
        .uploadDocument(fileName: file.name, filePath: file.path, fileBytes: file.bytes);
    if (mounted) {
      setState(() => _isUploadingLocal = false);
      uploadResult.when(
        success: (_) => AppSnackbar.show(context,
            message: 'Document uploaded.',
            variant: AppSnackbarVariant.success),
        failure: (error) => AppSnackbar.show(context,
            message: 'Upload failed: ${error.message}',
            variant: AppSnackbarVariant.error),
      );
    }
  }

  void _showDocumentSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Add Document', style: AppTextStyles.headingSmall),
              const SizedBox(height: AppSizes.p16),
              _docTile(Icons.camera_alt_rounded, 'Take Photo', () {
                Navigator.pop(ctx);
                _doUpload(FileType.image);
              }),
              _docTile(Icons.photo_library_rounded, 'Upload from Gallery', () {
                Navigator.pop(ctx);
                _doUpload(FileType.image);
              }),
              _docTile(Icons.folder_open_rounded, 'Browse Files', () {
                Navigator.pop(ctx);
                _doUpload(FileType.custom,
                    allowed: ['pdf', 'png', 'jpg', 'jpeg']);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _docTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.r12)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final documentsAsync =
        ref.watch(patientDocumentsNotifierProvider(widget.patient.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isUploadingLocal ? null : _showDocumentSheet,
              icon: _isUploadingLocal
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.textOnPrimary))
                  : const Icon(Icons.add, color: AppColors.textOnPrimary),
              label: Text('Add Document',
                  style: AppTextStyles.bodyBold
                      .copyWith(color: AppColors.textOnPrimary)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(AppSizes.r12))),
                elevation: 0,
              ),
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: AppColors.border),
        Expanded(
          child: documentsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (err, stack) => ErrorView(
              exception: err is AppException
                  ? err
                  : AppException.fromSupabaseException(err),
              onRetry: () => ref.invalidate(
                patientDocumentsNotifierProvider(widget.patient.id),
              ),
            ),
            data: (List<PatientDocument> docs) {
              if (docs.isEmpty) {
                return const EmptyState(
                  message: 'No documents uploaded yet',
                  icon: Icons.folder_open_rounded,
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  return PatientDocumentItem(doc: docs[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
