import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_note.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/medical_records_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/add_standalone_note_dialog.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_note_item.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

/// Renders a chronological feed of patient notes and allows adding standalone notes.
class PatientTabRecords extends ConsumerWidget {
  /// Creates a [PatientTabRecords].
  const PatientTabRecords({super.key, required this.patient});

  /// The patient entity.
  final Patient patient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<PatientNote>> notesAsync =
        ref.watch(patientNotesNotifierProvider(patient.id));

    // Watch notes provider to show SnackBar notifications on errors or successes
    ref.listen<AsyncValue<List<PatientNote>>>(
      patientNotesNotifierProvider(patient.id),
      (previous, next) {
        if (next is AsyncError) {
          final error = next.error;
          final String message = error is AppException
              ? error.message
              : error.toString();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: ElevatedButton.icon(
            onPressed: () => _showAddNoteDialog(context, ref),
            icon: const Icon(Icons.add, color: AppColors.textOnPrimary),
            label: Text(
              'Add Standalone Note',
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
        Expanded(
          child: notesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (Object err, StackTrace stack) => ErrorView(
              exception: err is AppException
                  ? err
                  : AppException.fromSupabaseException(err),
              onRetry: () =>
                  ref.invalidate(patientNotesNotifierProvider(patient.id)),
            ),
            data: (List<PatientNote> notes) {
              if (notes.isEmpty) {
                return const EmptyState(
                  message: 'No notes recorded yet',
                  icon: Icons.history_edu_rounded,
                );
              }

              return ListView.builder(
                itemCount: notes.length,
                padding: const EdgeInsets.only(bottom: AppSizes.p16),
                itemBuilder: (context, index) {
                  final PatientNote note = notes[index];
                  return PatientNoteItem(note: note);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddNoteDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AddStandaloneNoteDialog(
          onSave: (String noteText) {
            ref
                .read(patientNotesNotifierProvider(patient.id).notifier)
                .addNote(noteText: noteText);
          },
        );
      },
    );
  }
}
