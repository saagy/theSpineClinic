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
import 'package:spine_clinic_app/features/patient/presentation/widgets/add_note_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/app_badge.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';

/// Renders a single [PatientNote] in a chronological notes feed card.
///
/// Doctors and admins have full CRUD over all notes (Rule 6). Other staff
/// can only modify their own notes. Tap to edit, long-press or tap the
/// delete icon to remove.
class PatientNoteItem extends ConsumerWidget {
  /// Creates a [PatientNoteItem].
  const PatientNoteItem({super.key, required this.note});

  /// The patient note entity.
  final PatientNote note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Staff> staffAsync = ref.watch(staffProfileProvider(note.createdBy));
    final String dateStr = Formatters.formatDateMedium(note.createdAt);

    // Rule 6: Doctors and admins can modify any note; others only their own.
    final Staff? currentUser = ref.watch(currentUserProvider).value;
    final bool canModify = currentUser != null &&
        (currentUser.role == UserRole.doctor ||
         currentUser.role == UserRole.superAdmin ||
         currentUser.id == note.createdBy);

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
        onTap: canModify ? () => _showEditNoteSheet(context) : null,
        onLongPress: canModify ? () => _confirmDeleteNote(context, ref) : null,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Author name with role badge — constrained so long names
                  // don't push the delete icon off screen.
                  Expanded(
                    child: staffAsync.when(
                      data: (staff) {
                        final String roleName = switch (staff.role) {
                          UserRole.superAdmin => AppStrings.adminRoleLabel,
                          UserRole.receptionist => AppStrings.receptionistRoleLabel,
                          UserRole.doctor => AppStrings.doctorRoleLabel,
                        };
                        final String name = staff.isActive
                            ? '${staff.fullName} ($roleName)'
                            : '${staff.fullName} ($roleName, ${AppStrings.inactive})';
                        return Text(
                          name,
                          style: AppTextStyles.bodyBold.copyWith(color: AppColors.textPrimary),
                          softWrap: true,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                      loading: () => Text(AppStrings.loadingAuthor, style: AppTextStyles.bodySecondary),
                      error: (_, __) => Text(AppStrings.unknownAuthor, style: AppTextStyles.bodySecondary),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dateStr,
                        style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                      ),
                      if (canModify) ...[
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

  void _showEditNoteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddNoteSheet(
        patientId: note.patientId,
        initialText: note.noteText,
        noteId: note.id,
      ),
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
          loading: () => Text(AppStrings.loadingDetails, style: AppTextStyles.caption),
          error: (_, __) => Text(AppStrings.linkedAppointmentLabel, style: AppTextStyles.caption),
        ),
      ],
    );
  }
}
