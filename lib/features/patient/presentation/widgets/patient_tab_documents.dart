import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_document_item.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

/// Documents tab for the patient detail screen.
///
/// The + Add Document button triggers the native file/gallery picker directly
/// instead of showing a redundant intermediate bottom sheet, avoiding iOS
/// event-bubbling conflicts with mobile Safari's native file handler.
class PatientTabDocuments extends ConsumerStatefulWidget {
  const PatientTabDocuments({super.key, required this.patient});
  final Patient patient;

  @override
  ConsumerState<PatientTabDocuments> createState() =>
      _PatientTabDocumentsState();
}

class _PatientTabDocumentsState extends ConsumerState<PatientTabDocuments> {
  bool _isUploadingLocal = false;

  /// Opens the native file picker directly — no intermediate bottom sheet.
  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (!mounted) return;
    setState(() => _isUploadingLocal = true);
    final uploadResult = await ref
        .read(patientDocumentsNotifierProvider(widget.patient.id).notifier)
        .uploadDocument(
            fileName: file.name, filePath: file.path, fileBytes: file.bytes);
    if (!mounted) return;
    setState(() => _isUploadingLocal = false);
    uploadResult.when(
      success: (_) => AppSnackbar.show(context,
          message: AppStrings.documentUploaded,
          variant: AppSnackbarVariant.success),
      failure: (error) => AppSnackbar.show(context,
          message: AppStrings.fromKey(error.userMessageKey),
          variant: AppSnackbarVariant.error),
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
              onPressed: _isUploadingLocal ? null : _pickAndUpload,
              icon: _isUploadingLocal
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.textOnPrimary))
                  : const Icon(Icons.add, color: AppColors.textOnPrimary),
              label: Text(AppStrings.addDocument,
                  style: AppTextStyles.bodyBold
                      .copyWith(color: AppColors.textOnPrimary)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.p24, vertical: AppSizes.p14),
                shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.all(Radius.circular(AppSizes.r12))),
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
                  message: AppStrings.noDocumentsYet,
                  icon: Icons.folder_open_rounded,
                );
              }
              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => ref.invalidate(
                    patientDocumentsNotifierProvider(widget.patient.id)),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSizes.p8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    return PatientDocumentItem(doc: docs[index]);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
