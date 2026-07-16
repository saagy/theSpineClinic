import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_file_viewer.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

/// Resolves a patient document from route IDs, then renders the shared viewer.
class PatientDocumentViewerScreen extends ConsumerWidget {
  const PatientDocumentViewerScreen({
    required this.patientId,
    required this.documentId,
    super.key,
  });

  final String patientId;
  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<PatientDocument>> documents = ref.watch(
      patientDocumentsNotifierProvider(patientId),
    );

    return documents.when(
      loading: () => AppFileViewerScaffold(
        title: AppStrings.tabDocuments,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      error: (Object error, _) => AppFileViewerScaffold(
        title: AppStrings.tabDocuments,
        body: ErrorView(
          exception: error is AppException
              ? error
              : AppException.fromSupabaseException(error),
          onRetry: () =>
              ref.invalidate(patientDocumentsNotifierProvider(patientId)),
        ),
      ),
      data: (List<PatientDocument> documents) {
        final PatientDocument? document = _findDocument(documents);
        if (document == null) {
          return const AppFileViewerScaffold(
            title: AppStrings.tabDocuments,
            body: EmptyState(
              message: AppStrings.documentNotFound,
              icon: Icons.image_not_supported_outlined,
            ),
          );
        }
        return AppFileViewer(
          fileUrl: document.fileUrl,
          fileName: document.fileName,
        );
      },
    );
  }

  PatientDocument? _findDocument(List<PatientDocument> documents) {
    for (final PatientDocument document in documents) {
      if (document.id == documentId && document.patientId == patientId) {
        return document;
      }
    }
    return null;
  }
}
