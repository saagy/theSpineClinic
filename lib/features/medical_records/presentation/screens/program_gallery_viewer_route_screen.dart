import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/utils/viewer_navigation_helper.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/screens/program_gallery_viewer_screen.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

/// Resolves clinical scans from patient/program IDs and renders the gallery.
class ProgramGalleryViewerRouteScreen extends ConsumerWidget {
  const ProgramGalleryViewerRouteScreen({
    super.key,
    required this.patientId,
    required this.programId,
    this.initialIndex = 0,
  });

  final String patientId;
  final String programId;
  final int initialIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDocs = ref.watch(
      programDocumentsProvider(patientId: patientId, programId: programId),
    );
    final cs = Theme.of(context).colorScheme;
    final fallback = AppRoutes.patientProgramDetail
        .replaceFirst(':id', patientId)
        .replaceFirst(':programId', programId);

    return asyncDocs.when(
      loading: () => Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          backgroundColor: cs.surface,
          leading: IconButton(
            icon: Icon(Icons.close_rounded, color: cs.onSurface),
            tooltip: AppStrings.close,
            onPressed: () => closeViewer(context, fallbackLocation: fallback),
          ),
          title: const Text(AppStrings.imagingAttachments),
        ),
        body: Center(
          child: CircularProgressIndicator(color: cs.primary),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          backgroundColor: cs.surface,
          leading: IconButton(
            icon: Icon(Icons.close_rounded, color: cs.onSurface),
            tooltip: AppStrings.close,
            onPressed: () => closeViewer(context, fallbackLocation: fallback),
          ),
          title: const Text(AppStrings.imagingAttachments),
        ),
        body: ErrorView(
          exception: e is AppException
              ? e
              : AppException.fromSupabaseException(e),
          onRetry: () => ref.invalidate(
            programDocumentsProvider(
              patientId: patientId,
              programId: programId,
            ),
          ),
        ),
      ),
      data: (List<PatientDocument> docs) {
        if (docs.isEmpty) {
          return Scaffold(
            backgroundColor: cs.surface,
            appBar: AppBar(
              backgroundColor: cs.surface,
              leading: IconButton(
                icon: Icon(Icons.close_rounded, color: cs.onSurface),
                tooltip: AppStrings.close,
                onPressed: () =>
                    closeViewer(context, fallbackLocation: fallback),
              ),
              title: const Text(AppStrings.imagingAttachments),
            ),
            body: const Center(
              child: EmptyState(
                message: AppStrings.noAttachments,
                icon: Icons.image_not_supported_outlined,
              ),
            ),
          );
        }

        return ProgramGalleryViewerScreen(
          documents: docs,
          initialIndex: initialIndex,
          title: AppStrings.imagingAttachments,
          fallbackLocation: fallback,
        );
      },
    );
  }
}
