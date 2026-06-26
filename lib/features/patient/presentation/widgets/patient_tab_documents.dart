/// Documents tab — 2-column grid view with thumbnails for images.
///
/// Rule 13 — no raw Divider (uses SizedBox gap).
/// Rule 15/16 — colours via Theme.of(context).colorScheme.
library;

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_document_item.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

class PatientTabDocuments extends ConsumerStatefulWidget {
  const PatientTabDocuments({super.key, required this.patient});
  final Patient patient;

  @override
  ConsumerState<PatientTabDocuments> createState() =>
      _PatientTabDocumentsState();
}

class _PatientTabDocumentsState extends ConsumerState<PatientTabDocuments> {
  bool _isUploadingLocal = false;

  Future<void> _pickAndUpload() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final PlatformFile file = result.files.first;
    if (!mounted) return;
    final Uint8List? bytes = file.bytes;
    if (bytes == null) {
      AppSnackbar.show(context,
          message: AppStrings.fromKey('error_doc_file_too_large'),
          variant: AppSnackbarVariant.error);
      return;
    }
    setState(() => _isUploadingLocal = true);
    try {
      final Result<PatientDocument> uploadResult = await ref
          .read(patientDocumentsNotifierProvider(widget.patient.id).notifier)
          .uploadDocument(fileName: file.name, fileBytes: bytes);
      if (!mounted) return;
      uploadResult.when(
        success: (_) => AppSnackbar.show(context,
            message: AppStrings.documentUploaded,
            variant: AppSnackbarVariant.success),
        failure: (AppException error) => AppSnackbar.show(context,
            message: AppStrings.fromKey(error.userMessageKey),
            variant: AppSnackbarVariant.error),
      );
    } finally {
      if (mounted) setState(() => _isUploadingLocal = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final documentsAsync =
        ref.watch(patientDocumentsNotifierProvider(widget.patient.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isUploadingLocal)
          LinearProgressIndicator(color: cs.primary),
        Padding(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: AppButton(
            labelText: AppStrings.addDocument,
            onPressed: _isUploadingLocal ? null : _pickAndUpload,
            isLoading: _isUploadingLocal,
            icon: Icons.add,
            shape: AppButtonShape.pill,
            debounceMs: 1000,
          ),
        ),
        const SizedBox(height: AppSizes.p4),
        Expanded(
          child: RefreshIndicator(
            color: cs.primary,
            onRefresh: () async => ref.invalidate(
              patientDocumentsNotifierProvider(widget.patient.id),
            ),
            child: documentsAsync.when(
              loading: () => const SkeletonTileList(count: 4),
              error: (err, _) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  ErrorView(
                    exception: err is AppException
                        ? err
                        : AppException.fromSupabaseException(err),
                    onRetry: () => ref.invalidate(
                      patientDocumentsNotifierProvider(widget.patient.id),
                    ),
                  ),
                ],
              ),
              data: (List<PatientDocument> docs) {
                if (docs.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: AppSizes.p48),
                      EmptyState(
                        message: AppStrings.noDocumentsYet,
                        icon: Icons.folder_open_rounded,
                      ),
                    ],
                  );
                }
                return GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                      AppSizes.p16, 0, AppSizes.p16, AppSizes.p16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSizes.p12,
                    mainAxisSpacing: AppSizes.p12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    return PatientDocumentItem(
                      key: ValueKey(docs[index].id),
                      doc: docs[index],
                    ).animate().fadeIn(
                          duration: 250.ms,
                          delay: (index * 30).ms,
                        );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
