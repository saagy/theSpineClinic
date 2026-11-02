/// Documents tab — mixed grid of program folders and standalone documents.
///
/// Rule 13 — no raw Divider (uses SizedBox gap).
/// Rule 15/16 — colours via Theme.of(context).colorScheme.
library;

import 'package:flutter/material.dart';
import 'workspace_upload_button.dart';
import 'document_upload_feedback.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/screens/program_gallery_viewer_screen.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_document_groups.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_document_item.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_documents_skeleton.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/program_document_folder_tile.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

class PatientTabDocuments extends ConsumerStatefulWidget {
  const PatientTabDocuments({super.key, required this.patient});
  final Patient patient;

  @override
  ConsumerState<PatientTabDocuments> createState() => _PatientTabDocumentsState();
}

class _PatientTabDocumentsState extends ConsumerState<PatientTabDocuments> {
  void _openFolder(BuildContext context, ProgramDocumentGroup group) {
    ProgramGalleryViewerScreen.open(
      context,
      documents: group.documents,
      title: AppStrings.clinicalFindingsSection,
      patientId: widget.patient.id,
      programId: group.program?.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final groupsAsync = ref.watch(patientDocumentGroupsProvider(widget.patient.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WorkspaceUploadButton(patientId: widget.patient.id),
              const SizedBox(height: AppSizes.p12),
              DocumentUploadFeedback(patientId: widget.patient.id),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.p4),
        Expanded(
          child: RefreshIndicator(
            color: cs.primary,
            onRefresh: () async {
              ref.invalidate(patientDocumentsNotifierProvider(widget.patient.id));
              ref.invalidate(patientDocumentGroupsProvider(widget.patient.id));
            },
            child: groupsAsync.when(
              loading: () => const PatientDocumentsSkeleton(),
              error: (err, _) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  ErrorView(
                    exception: err is AppException ? err : AppException.fromSupabaseException(err),
                    onRetry: () => ref.invalidate(patientDocumentGroupsProvider(widget.patient.id)),
                  ),
                ],
              ),
              data: (DocumentGroups groups) {
                if (groups.isEmpty) {
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
                return _DocumentsGrid(groups: groups, onOpenFolder: _openFolder);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _DocumentsGrid extends StatelessWidget {
  const _DocumentsGrid({required this.groups, required this.onOpenFolder});

  final DocumentGroups groups;
  final void Function(BuildContext, ProgramDocumentGroup) onOpenFolder;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth < 600 ? 2 : (screenWidth / 300).floor().clamp(2, 6);

    final items = <_GridItem>[
      ...groups.folders.map((g) => _GridItem.folder(g)),
      ...groups.standalone.map((d) => _GridItem.doc(d)),
    ];

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppSizes.p16, 0, AppSizes.p16, AppSizes.p16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppSizes.p12,
        mainAxisSpacing: AppSizes.p12,
        childAspectRatio: 0.72,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return item.when(
          folder: (g) => ProgramDocumentFolderTile(
            key: ValueKey('folder-${g.program?.id ?? g.documents.first.id}'),
            group: g,
            onTap: () => onOpenFolder(context, g),
          ),
          doc: (d) => PatientDocumentItem(
            key: ValueKey('doc-${d.id}'),
            document: d,
          ).animate().fadeIn(duration: 250.ms, delay: (index * 30).ms),
        );
      },
    );
  }
}

class _GridItem {
  const _GridItem.folder(ProgramDocumentGroup g) : folderValue = g, docValue = null;

  const _GridItem.doc(PatientDocument d) : docValue = d, folderValue = null;

  final ProgramDocumentGroup? folderValue;
  final PatientDocument? docValue;

  T when<T>({
    required T Function(ProgramDocumentGroup) folder,
    required T Function(PatientDocument) doc,
  }) {
    final f = folderValue;
    if (f != null) return folder(f);
    return doc(docValue!);
  }
}
