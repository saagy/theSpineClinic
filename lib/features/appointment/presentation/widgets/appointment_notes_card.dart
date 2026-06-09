import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_note.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/medical_records_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/add_standalone_note_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';

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

    return noteAsync.when(
      loading: () => const SectionCard(
        title: 'Visit Notes',
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, stack) => SectionCard(
        title: 'Visit Notes',
        child: Text(
          'Error loading notes: ${error.toString()}',
          style: AppTextStyles.body.copyWith(color: AppColors.error),
        ),
      ),
      data: (note) {
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
              ElevatedButton.icon(
                onPressed: () => _showNoteDialog(context, ref, note),
                icon: const Icon(Icons.add, color: AppColors.textOnPrimary),
                label: Text(
                  note != null ? 'Edit Note' : 'Add Note',
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
          ),
        );
      },
    );
  }

  void _showNoteDialog(BuildContext context, WidgetRef ref, PatientNote? note) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AddStandaloneNoteDialog(
          initialText: note?.noteText,
          onSave: (String noteText) {
            ref
                .read(appointmentNoteProvider(appointmentId).notifier)
                .saveNote(
                  noteText: noteText,
                  patientId: patientId,
                );
          },
        );
      },
    );
  }
}
