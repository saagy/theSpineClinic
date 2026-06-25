/// Card component showing visit notes for an appointment.
///
/// When a note exists and the user can modify it, edit/delete actions are
/// compact icon buttons in the card header's trailing slot — not full-width
/// pills competing with page-level actions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_note.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/medical_records_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_notes_list_notifier.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/add_note_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';

class AppointmentNotesCard extends ConsumerWidget {
  const AppointmentNotesCard({
    super.key,
    required this.appointmentId,
    required this.patientId,
  });

  final String appointmentId;
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteAsync = ref.watch(appointmentNoteProvider(appointmentId));
    final Staff? currentUser = ref.watch(currentUserProvider).value;

    return noteAsync.when(
      loading: () => const SectionCard(
        title: 'Visit Notes',
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, stack) {
        final AppException ex = error is AppException
            ? error
            : UnknownException(message: '$error');
        return SectionCard(
          title: 'Visit Notes',
          child: Text(
            AppStrings.fromKey(ex.userMessageKey),
            style: AppTextStyles.body.copyWith(color: AppColors.error),
          ),
        );
      },
      data: (note) {
        final bool canModify = note != null && currentUser != null &&
            (currentUser.role == UserRole.doctor ||
             currentUser.role == UserRole.superAdmin ||
             currentUser.id == note.createdBy);

        final Widget? action = (note != null && canModify)
            ? _NoteActions(
                onEdit: () => _showNoteSheet(context, note),
                onDelete: () => _confirmDeleteNote(context, ref, note),
              )
            : null;

        return SectionCard(
          title: 'Visit Notes',
          action: action,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (note != null && note.noteText.isNotEmpty)
                Text(note.noteText, style: AppTextStyles.body)
              else if (note == null)
                AppButton(
                  labelText: 'Add Note',
                  onPressed: () => _showNoteSheet(context, null),
                  icon: Icons.add,
                  shape: AppButtonShape.pill,
                ),
            ],
          ),
        );
      },
    );
  }

  void _showNoteSheet(BuildContext context, PatientNote? note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddNoteSheet(
        patientId: patientId,
        initialText: note?.noteText,
        noteId: note?.id,
        appointmentId: appointmentId,
      ),
    );
  }

  Future<void> _confirmDeleteNote(
      BuildContext context, WidgetRef ref, PatientNote note) async {
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
            AppSnackbar.show(context,
                message: AppStrings.noteDeleted,
                variant: AppSnackbarVariant.success);
            ref.invalidate(patientNotesListProvider(note.patientId));
            ref.invalidate(patientNotesNotifierProvider(note.patientId));
            ref.invalidate(appointmentNoteProvider(note.appointmentId!));
          },
          failure: (error) {
            AppSnackbar.show(context,
                message: error.message, variant: AppSnackbarVariant.error);
          },
        );
      }
    }
  }
}

/// Compact edit + delete icon buttons for the note card header.
class _NoteActions extends StatelessWidget {
  const _NoteActions({required this.onEdit, required this.onDelete});
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          color: AppColors.textSecondary,
          tooltip: AppStrings.edit,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: onEdit,
        ),
        const SizedBox(width: AppSizes.p4),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, size: 20),
          color: AppColors.error,
          tooltip: AppStrings.delete,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: onDelete,
        ),
      ],
    );
  }
}
