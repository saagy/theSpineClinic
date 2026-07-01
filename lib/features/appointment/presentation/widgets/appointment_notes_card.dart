/// Card component showing visit notes for an appointment.
///
/// Refactored to match cardless document layout design with left color border.
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
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/eyebrow_label.dart';

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
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        noteAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.p16),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (error, stack) {
            final AppException ex = error is AppException
                ? error
                : UnknownException(message: '$error');
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.p16),
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

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EyebrowLabel(
                  text: AppStrings.notes,
                  isUppercase: false,
                  action: note != null && canModify
                      ? _NoteActions(
                          onEdit: () => _showNoteSheet(context, note),
                          onDelete: () => _confirmDeleteNote(context, ref, note),
                        )
                      : null,
                ),
                const SizedBox(height: AppSizes.p8),
                if (note != null && note.noteText.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: AppSizes.p4),
                    padding: const EdgeInsets.fromLTRB(AppSizes.p12, AppSizes.p2, 0, AppSizes.p2),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 4.0,
                        ),
                      ),
                    ),
                    child: Text(
                      note.noteText,
                      style: AppTextStyles.body,
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () => _showNoteSheet(context, null),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: AppSizes.p14),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.border,
                          width: 1.0,
                        ),
                        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r12)),
                        color: AppColors.neutralBg.withValues(alpha: 0.2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            color: AppColors.textSecondary,
                            size: AppSizes.iconSmall,
                          ),
                          const SizedBox(width: AppSizes.p8),
                          Text(
                            'Add visit note...',
                            style: AppTextStyles.bodySecondary.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
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

/// Compact edit + delete icon buttons.
class _NoteActions extends StatelessWidget {
  const _NoteActions({required this.onEdit, required this.onDelete});
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 22),
          color: cs.onSurfaceVariant,
          tooltip: AppStrings.edit,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          onPressed: onEdit,
        ),
        const SizedBox(width: AppSizes.p4),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, size: 22),
          color: cs.error,
          tooltip: AppStrings.delete,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          onPressed: onDelete,
        ),
      ],
    );
  }
}
