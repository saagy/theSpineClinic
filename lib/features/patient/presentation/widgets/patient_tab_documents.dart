import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_document_item.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

/// Renders a list/grid of uploaded documents and an upload button for a patient.
class PatientTabDocuments extends ConsumerStatefulWidget {
  /// Creates a [PatientTabDocuments].
  const PatientTabDocuments({super.key, required this.patient});

  /// The patient entity.
  final Patient patient;

  @override
  ConsumerState<PatientTabDocuments> createState() =>
      _PatientTabDocumentsState();
}

class _PatientTabDocumentsState extends ConsumerState<PatientTabDocuments> {
  bool _isUploadingLocal = false;

  Future<void> _handleUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;

    setState(() => _isUploadingLocal = true);

    final uploadResult = await ref
        .read(patientDocumentsNotifierProvider(widget.patient.id).notifier)
        .uploadDocument(
          fileName: file.name,
          filePath: file.path,
          fileBytes: file.bytes,
        );

    if (mounted) {
      setState(() => _isUploadingLocal = false);

      uploadResult.when(
        success: (_) {
          AppSnackbar.show(
            context,
            message: 'Document uploaded successfully.',
            variant: AppSnackbarVariant.success,
          );
        },
        failure: (error) {
          AppSnackbar.show(
            context,
            message: AppStrings.fromKey(error.userMessageKey),
            variant: AppSnackbarVariant.error,
          );
        },
      );
    }
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
          child: AppButton(
            labelText: AppStrings.upload,
            isLoading: _isUploadingLocal,
            onPressed: _isUploadingLocal ? null : _handleUpload,
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
