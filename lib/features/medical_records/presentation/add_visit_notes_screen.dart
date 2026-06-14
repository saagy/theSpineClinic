import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/add_visit_notes_controller.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/notes_form.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/security_restriction_view.dart';
import 'package:spine_clinic_app/shared/widgets/app_back_button.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/info_row.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';

/// Screen allowing authorized doctors or super admins to add/edit visit notes.
class AddVisitNotesScreen extends ConsumerWidget {
  /// Creates an [AddVisitNotesScreen].
  const AddVisitNotesScreen({super.key, required this.appointmentId});

  /// The target appointment's unique ID.
  final String appointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(addVisitNotesControllerProvider(appointmentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.addVisitNotes, style: AppTextStyles.headingSmall),
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        leading: const AppBackButton(),
      ),
      body: stateAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (Object error, StackTrace stack) => ErrorView(
          exception: error is AppException ? error : AppException.fromSupabaseException(error),
          onRetry: () => ref.invalidate(addVisitNotesControllerProvider(appointmentId)),
        ),
        data: (state) {
          if (!state.isAuthorized) {
            return const SecurityRestrictionView();
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSizes.p24),
                  child: SectionCard(
                    child: Column(
                      children: [
                        InfoRow(label: 'Patient', value: state.patient.fullName),
                        InfoRow(
                          label: AppStrings.date,
                          value: Formatters.formatDateMedium(state.appointment.scheduledAt),
                        ),
                        InfoRow(
                          label: AppStrings.time,
                          value: Formatters.formatTime(state.appointment.scheduledAt),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
                  child: NotesForm(
                    appointment: state.appointment,
                    note: state.note,
                    appointmentId: appointmentId,
                  ),
                ),
                const SizedBox(height: AppSizes.p32),
              ],
            ),
          );
        },
      ),
    );
  }
}
