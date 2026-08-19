/// Compact action buttons and delete handling for appointment visit notes.
///
/// Rule 1 — keep files under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_note.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/medical_records_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_notes_list_notifier.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';

/// Compact edit + delete icon buttons for notes.
class NoteHeaderActions extends StatelessWidget {
  const NoteHeaderActions({
    super.key,
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          color: cs.onSurfaceVariant,
          tooltip: AppStrings.edit,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          onPressed: onEdit,
        ),
        const SizedBox(width: AppSizes.p4),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, size: 20),
          color: cs.error,
          tooltip: AppStrings.delete,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          onPressed: onDelete,
        ),
      ],
    );
  }

  /// Displays confirmation dialog and deletes the note.
  static Future<void> confirmAndDelete({
    required BuildContext context,
    required WidgetRef ref,
    required PatientNote note,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmationDialog(
        title: AppStrings.deleteNote,
        message: AppStrings.confirmDeleteNote,
        confirmLabel: AppStrings.delete,
        cancelLabel: AppStrings.cancel,
        isDestructive: true,
      ),
    );
    if (confirm == true && context.mounted) {
      final repo = ref.read(patientNotesRepositoryProvider);
      final result = await repo.deleteNote(note.id);
      if (context.mounted) {
        result.when(
          success: (_) {
            AppSnackbar.show(
              context,
              message: AppStrings.noteDeleted,
              variant: AppSnackbarVariant.success,
            );
            ref.invalidate(patientNotesListProvider(note.patientId));
            ref.invalidate(patientNotesNotifierProvider(note.patientId));
            if (note.appointmentId != null) {
              ref.invalidate(appointmentNoteProvider(note.appointmentId!));
            }
          },
          failure: (error) {
            AppSnackbar.show(
              context,
              message: error.message,
              variant: AppSnackbarVariant.error,
            );
          },
        );
      }
    }
  }
}
