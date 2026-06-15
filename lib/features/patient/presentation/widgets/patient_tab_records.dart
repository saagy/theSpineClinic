import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_note.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/medical_records_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/add_note_sheet.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_note_item.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

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
            onPressed: () => _showAddNoteSheet(context),
            icon: const Icon(Icons.add, color: AppColors.textOnPrimary),
            label: Text(
              'Add Note',
              style: AppTextStyles.bodyBold.copyWith(color: AppColors.textOnPrimary),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.p24, vertical: AppSizes.p14),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(AppSizes.r6)),
              ),
            ),
          ),
        ),
        Expanded(
          child: notesAsync.when(
            loading: () => const SkeletonTileList(count: 4),
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

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  ref.invalidate(patientNotesNotifierProvider(patient.id));
                  await ref.read(
                      patientNotesNotifierProvider(patient.id).future);
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: notes.length,
                  padding: const EdgeInsets.only(bottom: AppSizes.p16),
                  itemBuilder: (context, index) {
                    final PatientNote note = notes[index];
                    return PatientNoteItem(note: note)
                        .animate()
                        .fadeIn(duration: 250.ms, delay: (index * 30).ms);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddNoteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddNoteSheet(patientId: patient.id),
    );
  }
}
