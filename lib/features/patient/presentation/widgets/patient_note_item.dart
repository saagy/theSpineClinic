import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_note.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/medical_records_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_notes_list_notifier.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/add_note_sheet.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_note_appointment_badge.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

/// Renders a single [PatientNote] in a rounded 16px card.
class PatientNoteItem extends ConsumerWidget {
  const PatientNoteItem({super.key, required this.note});
  final PatientNote note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffProfileProvider(note.createdBy));
    final String dateStr = Formatters.formatDateMedium(note.createdAt);
    final cs = Theme.of(context).colorScheme;

    final Staff? currentUser = ref.watch(currentUserProvider).value;
    final bool canModify = currentUser != null &&
        (currentUser.role == UserRole.doctor ||
         currentUser.role == UserRole.superAdmin ||
         currentUser.id == note.createdBy);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p6),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppSizes.borderRadiusCard,
        border: Border.all(color: cs.outlineVariant.withAlpha(90)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppSizes.borderRadiusCard,
        child: InkWell(
          borderRadius: AppSizes.borderRadiusCard,
          onTap: canModify ? () => _showEditNoteSheet(context) : null,
          onLongPress: canModify ? () => _confirmDeleteNote(context, ref) : null,
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: staffAsync.when(
                          data: (staff) {
                            final String roleName = switch (staff.role) {
                              UserRole.superAdmin => AppStrings.adminRoleLabel,
                              UserRole.receptionist => AppStrings.receptionistRoleLabel,
                              UserRole.doctor => AppStrings.doctorRoleLabel,
                            };
                            return Row(
                              key: ValueKey('author_${staff.id}'),
                              children: [
                                Flexible(
                                  child: Text(
                                    staff.fullName,
                                    style: AppTextStyles.bodyBold.copyWith(color: cs.onSurface),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: AppSizes.p6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(AppSizes.r4),
                                  ),
                                  child: Text(
                                    roleName,
                                    style: AppTextStyles.captionMedium.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                          loading: () => const Align(
                            alignment: Alignment.centerLeft,
                            child: SkeletonBox(width: 130, height: 14, borderRadius: AppSizes.r4),
                          ),
                          error: (_, __) => Text(
                            AppStrings.unknownAuthor,
                            style: AppTextStyles.bodySecondary.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.p8),
                    Text(dateStr, style: AppTextStyles.captionMedium.copyWith(color: cs.onSurfaceVariant)),
                    if (canModify) ...[
                      const SizedBox(width: AppSizes.p4),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        icon: Icon(Icons.delete_outline_rounded, size: 18, color: cs.error),
                        onPressed: () => _confirmDeleteNote(context, ref),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSizes.p10),
                Text(note.noteText, style: AppTextStyles.body.copyWith(color: cs.onSurface, height: 1.4)),
                if (note.appointmentId != null) ...[
                  const SizedBox(height: AppSizes.p12),
                  PatientNoteAppointmentBadge(appointmentId: note.appointmentId!),
                ],
              ],
            ),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.r16)),
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
            AppSnackbar.show(context, message: AppStrings.noteDeleted, variant: AppSnackbarVariant.success);
            ref.invalidate(patientNotesListProvider(note.patientId));
            ref.invalidate(patientNotesNotifierProvider(note.patientId));
            if (note.appointmentId != null) {
              ref.invalidate(appointmentNoteProvider(note.appointmentId!));
            }
          },
          failure: (error) => AppSnackbar.show(context, message: error.message, variant: AppSnackbarVariant.error),
        );
      }
    }
  }
}
