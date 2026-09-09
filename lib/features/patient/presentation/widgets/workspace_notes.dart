import 'package:flutter/material.dart';
import 'package:spine_clinic_app/shared/widgets/record_action_menu.dart';
import 'package:spine_clinic_app/shared/widgets/record_filter_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/record_skeleton.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_note_filters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_note.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_note_actions_controller.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_notes_list_notifier.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_note_editor.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/record_section.dart';

class WorkspaceNotes extends ConsumerWidget {
  const WorkspaceNotes({super.key, required this.patientId});
  final String patientId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(patientNotesListProvider(patientId));
    final notifier = ref.read(patientNotesListProvider(patientId).notifier);
    return RecordSection(
      showTitle: false,
      trailing: RecordFilterButton(
        compact: true,
        onPressed: () => WorkspaceNoteFilters.show(context, ref, patientId),
      ),
      title: AppStrings.notes,
      action: AppStrings.addNote,
      primaryAction: true,
      onAction: () => WorkspaceNoteEditor.show(context, patientId),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSizes.p12,
            runSpacing: AppSizes.p8,
            children: [
              if (state.dateFrom != null || state.dateTo != null)
                TextButton(
                  onPressed: notifier.clearFilters,
                  child: Text(
                    '${AppStrings.clearFilters} · ${state.dateFrom == null ? '' : Formatters.formatDateShort(state.dateFrom!)}'
                    ' – ${state.dateTo == null ? '' : Formatters.formatDateShort(state.dateTo!.subtract(const Duration(days: 1)))}',
                  ),
                ),
            ],
          ),
          if (state.isLoading && state.notes.isEmpty) const RecordSkeleton(),
          if (state.errorMessage != null)
            RecordMessage(
              message: AppStrings.patientSectionError,
              action: AppStrings.retry,
              onAction: () => notifier.refresh(silent: false),
            ),
          if (!state.isLoading && state.errorMessage == null && state.notes.isEmpty)
            const RecordMessage(message: AppStrings.noNotesRecorded),
          for (final note in state.notes) _Note(note: note),
          if (state.hasMore)
            TextButton(
              onPressed: state.isLoadingMore ? null : notifier.loadMore,
              child: const Text(AppStrings.showMoreRecords),
            ),
        ],
      ),
    );
  }
}

class _Note extends ConsumerWidget {
  const _Note({required this.note});
  final PatientNote note;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final author = ref.watch(staffProfileProvider(note.createdBy));
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSizes.p12,
                  runSpacing: AppSizes.p4,
                  children: [
                    Text(author.value?.fullName ?? AppStrings.recordedBy, style: AppTextStyles.captionBold),
                    Text(
                      Formatters.formatDateTime(note.createdAt),
                      style: AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (note.appointmentId != null)
                IconButton(
                  tooltip: AppStrings.viewAppointment,
                  icon: const Icon(Icons.event_note_outlined, size: AppSizes.iconSmall),
                  onPressed: () =>
                      context.push(AppRoutes.appointmentDetail.replaceFirst(':id', note.appointmentId!)),
                ),
              RecordActionMenu<String>(
                tooltip: AppStrings.moreActions,
                actions: const [
                  RecordMenuAction('edit', AppStrings.edit, Icons.edit_outlined),
                  RecordMenuAction('delete', AppStrings.delete, Icons.delete_outline, destructive: true),
                ],
                onSelected: (action) async {
                  if (ref.read(currentUserProvider).value?.isActive != true) return;
                  if (action == 'edit') {
                    await WorkspaceNoteEditor.show(context, note.patientId, note: note);
                  } else {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (_) => const ConfirmationDialog(
                        title: AppStrings.deleteNote,
                        message: AppStrings.confirmDeleteNote,
                        confirmLabel: AppStrings.delete,
                        isDestructive: true,
                      ),
                    );
                    if (confirmed != true || !context.mounted) return;
                    final result = await ref.read(patientNoteActionsControllerProvider.notifier).delete(note);
                    if (!context.mounted) return;
                    result.when(
                      success: (_) => AppSnackbar.show(context, message: AppStrings.noteDeleted),
                      failure: (e) => AppSnackbar.show(
                        context,
                        message: AppStrings.fromKey(e.userMessageKey),
                        variant: AppSnackbarVariant.error,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p8),
          SelectableText(note.noteText, style: AppTextStyles.body),
        ],
      ),
    );
  }
}
