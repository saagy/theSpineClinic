import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
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

/// Renders a single [PatientNote] in a chronological notes feed card.
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
                        UserRole.superAdmin => 'Admin',
                        UserRole.receptionist => 'Receptionist',
                        UserRole.doctor => 'Doctor',
                      };
                      return Text(
                        '${staff.fullName} ($roleName)',
                        style: AppTextStyles.bodyBold.copyWith(color: AppColors.textPrimary),
                      );
                    },
                    loading: () => const Text('Loading...', style: AppTextStyles.bodySecondary),
                    error: (_, __) => const Text('Unknown Author', style: AppTextStyles.bodySecondary),
                  ),
                  Text(
                    dateStr,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
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
      builder: (BuildContext context) {
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
              label: 'On appointment: ${appt.type.displayLabel} ($apptDate)',
              textColor: AppColors.info,
              backgroundColor: AppColors.infoBg,
            );
          },
          loading: () => const Text('Loading details...', style: AppTextStyles.caption),
          error: (_, __) => const Text('Linked Appointment', style: AppTextStyles.caption),
        ),
      ],
    );
  }
}
