/// Card component showing visit notes for an appointment.
///
/// Rule 1 — keep files under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_note.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/medical_records_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/add_note_sheet.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_note_actions.dart';
import 'package:spine_clinic_app/shared/widgets/eyebrow_label.dart';

/// Section card for viewing, adding, and editing appointment visit notes.
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
    final colorScheme = theme.colorScheme;
    final clinic = ClinicColors.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.p16,
        vertical: AppSizes.p8,
      ),
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        border: Border.all(color: colorScheme.outlineVariant, width: 0.5),
        boxShadow: [clinic.cardShadow],
      ),
      child: noteAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSizes.p16),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) {
          final AppException ex = error is AppException
              ? error
              : UnknownException(message: '$error');
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
            child: Text(
              AppStrings.fromKey(ex.userMessageKey),
              style: AppTextStyles.body.copyWith(color: colorScheme.error),
            ),
          );
        },
        data: (note) {
          final bool canModify = note != null &&
              currentUser != null &&
              (currentUser.role == UserRole.doctor ||
                  currentUser.role == UserRole.superAdmin ||
                  currentUser.id == note.createdBy);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EyebrowLabel(
                text: AppStrings.visitNotes,
                isUppercase: false,
                action: note != null && canModify
                    ? NoteHeaderActions(
                        onEdit: () => _showNoteSheet(context, note),
                        onDelete: () => NoteHeaderActions.confirmAndDelete(
                          context: context,
                          ref: ref,
                          note: note,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: AppSizes.p8),
              if (note != null && note.noteText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.p12,
                    AppSizes.p8,
                    AppSizes.p12,
                    AppSizes.p8,
                  ),
                  decoration: BoxDecoration(
                    color: clinic.neutralContainer.withValues(alpha: 0.2),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(AppSizes.r8),
                    ),
                    border: Border(
                      left: BorderSide(
                        color: colorScheme.primary,
                        width: 3.5,
                      ),
                    ),
                  ),
                  child: Text(
                    note.noteText,
                    style: AppTextStyles.body.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                )
              else
                InkWell(
                  onTap: () => _showNoteSheet(context, null),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(AppSizes.r12),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.p14),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: colorScheme.outlineVariant,
                        width: 1.0,
                      ),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(AppSizes.r12),
                      ),
                      color: clinic.neutralContainer.withValues(alpha: 0.15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          color: colorScheme.primary,
                          size: AppSizes.iconSmall,
                        ),
                        const SizedBox(width: AppSizes.p8),
                        Text(
                          AppStrings.addVisitNotePrompt,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
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
}
