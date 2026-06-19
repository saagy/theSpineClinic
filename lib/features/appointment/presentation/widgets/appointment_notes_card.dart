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
import 'package:spine_clinic_app/features/patient/presentation/widgets/add_note_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';

/// Card component showing visit notes for an appointment with a button to edit/add notes.
class AppointmentNotesCard extends ConsumerWidget {
  /// Creates an [AppointmentNotesCard].
  const AppointmentNotesCard({
    super.key,
    required this.appointmentId,
    required this.patientId,
  });

  /// Unique ID of the appointment.
  final String appointmentId;

  /// Unique ID of the patient.
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

        return SectionCard(
          title: 'Visit Notes',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (note != null && note.noteText.isNotEmpty) ...[
                Text(
                  note.noteText,
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: AppSizes.p16),
              ],
              if (note != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showNoteSheet(context, note),
                        icon: const Icon(Icons.add, color: AppColors.textOnPrimary),
                        label: Text(
                          'Edit Note',
                          style: AppTextStyles.bodyBold.copyWith(color: AppColors.textOnPrimary),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: AppSizes.p12),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(AppSizes.r6)),
                          ),
                        ),
                      ),
                    ),
                    if (canModify) ...[
                      const SizedBox(width: AppSizes.p12),
                      OutlinedButton(
                        onPressed: () => _confirmDeleteNote(context, ref, note),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: AppSizes.p12, horizontal: AppSizes.p12),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(AppSizes.r6)),
                          ),
                        ),
                        child: const Icon(Icons.delete_outline_rounded, size: 20),
                      ),
                    ],
                  ],
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: () => _showNoteSheet(context, null),
                  icon: const Icon(Icons.add, color: AppColors.textOnPrimary),
                  label: Text(
                    'Add Note',
                    style: AppTextStyles.bodyBold.copyWith(color: AppColors.textOnPrimary),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.p12),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(AppSizes.r6)),
                    ),
                  ),
                ),
              ],
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

  Future<void> _confirmDeleteNote(BuildContext context, WidgetRef ref, PatientNote note) async {
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
