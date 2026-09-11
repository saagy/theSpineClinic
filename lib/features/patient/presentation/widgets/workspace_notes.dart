import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_notes_list_notifier.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_note_editor.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_note_filters.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_note_row.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_tab_header.dart';
import 'package:spine_clinic_app/shared/widgets/record_filter_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/record_section.dart';
import 'package:spine_clinic_app/shared/widgets/record_skeleton.dart';

class WorkspaceNotes extends ConsumerWidget {
  const WorkspaceNotes({super.key, required this.patientId});
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(patientNotesListProvider(patientId));
    final notifier = ref.read(patientNotesListProvider(patientId).notifier);
    final cs = Theme.of(context).colorScheme;
    final int activeCount = (state.dateFrom != null || state.dateTo != null) ? 1 : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WorkspaceTabHeader(
          title: AppStrings.notes,
          filterButton: RecordFilterButton(
            activeFiltersCount: activeCount,
            onPressed: () => WorkspaceNoteFilters.show(context, ref, patientId),
          ),
          actionLabel: AppStrings.addNote,
          onAction: () => WorkspaceNoteEditor.show(context, patientId),
        ),
        if (state.dateFrom != null || state.dateTo != null) ...[
          const SizedBox(height: AppSizes.p10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: notifier.clearFilters,
              icon: const Icon(Icons.close, size: AppSizes.iconSmall),
              label: Text(
                '${AppStrings.clearFilters} · ${state.dateFrom == null ? '' : Formatters.formatDateShort(state.dateFrom!)}'
                ' – ${state.dateTo == null ? '' : Formatters.formatDateShort(state.dateTo!.subtract(const Duration(days: 1)))}',
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSizes.p14),
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppSizes.r12),
            border: Border.all(color: cs.outlineVariant.withAlpha(80)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.isLoading && state.notes.isEmpty) const RecordSkeleton(),
              if (state.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(AppSizes.p16),
                  child: RecordMessage(
                    message: AppStrings.patientSectionError,
                    action: AppStrings.retry,
                    onAction: () => notifier.refresh(silent: false),
                  ),
                ),
              if (!state.isLoading && state.errorMessage == null && state.notes.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(AppSizes.p24),
                  child: RecordMessage(message: AppStrings.noNotesRecorded),
                ),
              for (int i = 0; i < state.notes.length; i++) ...[
                WorkspaceNoteRow(note: state.notes[i]),
                if (i < state.notes.length - 1) const Divider(height: AppSizes.borderWidth),
              ],
              if (state.hasMore)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
                  child: TextButton(
                    onPressed: state.isLoadingMore ? null : notifier.loadMore,
                    child: const Text(AppStrings.showMoreRecords),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
