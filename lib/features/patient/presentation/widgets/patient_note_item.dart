import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_note.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/medical_records_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/add_standalone_note_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/app_badge.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';

/// Renders a single [PatientNote] in a chronological notes feed card.
///
/// Supports tap-to-edit and long-press-to-delete for any staff with view access.
class PatientNoteItem extends ConsumerWidget {
  /// Creates a [PatientNoteItem].
  const PatientNoteItem({super.key, required this.note});

  /// The patient note entity.
  final PatientNote note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Staff> staffAsync = ref.watch(staffProfileProvider(note.createdBy));
    final String dateStr = Formatters.formatDateMedium(note.createdAt);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.r8)),
        side: BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r8)),
        onTap: () => _showEditNoteDialog(context, ref),
        onLongPress: () => _confirmDeleteNote(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  staffAsync.when(
                    data: (staff) {
                      final String roleName = switch (staff.role) {
                        UserRole.superAdmin => AppStrings.adminRoleLabel,
                        UserRole.receptionist => AppStrings.receptionistRoleLabel,
                        UserRole.doctor => AppStrings.doctorRoleLabel,
                      };
                      return Text(
                        '${staff.fullName} ($roleName)',
                        style: AppTextStyles.bodyBold.copyWith(color: AppColors.textPrimary),
                      );
                    },
                    loading: () => const Text(AppStrings.loadingAuthor, style: AppTextStyles.bodySecondary),
                    error: (_, __) => const Text(AppStrings.unknownAuthor, style: AppTextStyles.bodySecondary),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dateStr,
                        style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                      ),
                      const SizedBox(width: AppSizes.p8),
                      GestureDetector(
                        onTap: () => _confirmDeleteNote(context, ref),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          size: AppSizes.iconSmall,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.p8),
              Text(
                note.noteText,
                style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
              ),
              if (note.appointmentId != null) ...[
                const SizedBox(height: AppSizes.p12),
                _AppointmentLinkIndicator(appointmentId: note.appointmentId!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showEditNoteDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AddStandaloneNoteDialog(
          initialText: note.noteText,
          onSave: (String noteText) {
            ref
                .read(patientNotesNotifierProvider(note.patientId).notifier)
                .updateExistingNote(
                  noteId: note.id,
                  noteText: noteText,
                );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteNote(BuildContext context, WidgetRef ref) async {
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
            if (note.appointmentId != null) {
              ref.invalidate(appointmentNoteProvider(note.appointmentId!));
            }
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

class _AppointmentLinkIndicator extends ConsumerWidget {
  const _AppointmentLinkIndicator({required this.appointmentId});
  final String appointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Appointment> appointmentAsync = ref.watch(singleAppointmentProvider(appointmentId));

    return Row(
      children: [
        const Icon(Icons.link_rounded, size: AppSizes.iconSmall, color: AppColors.info),
        const SizedBox(width: AppSizes.p4),
        appointmentAsync.when(
          data: (appt) {
            final apptDate = Formatters.formatDateMedium(appt.scheduledAt);
            return AppBadge(
              label: '${AppStrings.onAppointmentPrefix}${appt.type.displayLabel} ($apptDate)',
              textColor: AppColors.info,
              backgroundColor: AppColors.infoBg,
            );
          },
          loading: () => const Text(AppStrings.loadingDetails, style: AppTextStyles.caption),
          error: (_, __) => const Text(AppStrings.linkedAppointmentLabel, style: AppTextStyles.caption),
        ),
      ],
    );
  }
}
