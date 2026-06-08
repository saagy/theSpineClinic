import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_note.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/medical_records_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';

/// Read-only visit notes card displayed in AppointmentDetailScreen.
class AppointmentReadOnlyNotesCard extends ConsumerWidget {
  /// Creates an [AppointmentReadOnlyNotesCard].
  const AppointmentReadOnlyNotesCard({
    super.key,
    required this.appointment,
    required this.activeDoctors,
  });

  /// The appointment entity.
  final Appointment appointment;

  /// Active doctors assigned to the appointment.
  final List<AppointmentDoctorDetail> activeDoctors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRole = ref.watch(currentUserProvider).value?.role;
    if (userRole == null) return const SizedBox.shrink();

    final AsyncValue<PatientNote?> noteAsync = ref.watch(appointmentNoteProvider(appointment.id));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
      child: SectionCard(
        title: AppStrings.notes,
        child: noteAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (Object error, StackTrace stack) => Text(
            'Error loading notes.',
            style: AppTextStyles.body.copyWith(color: AppColors.error),
          ),
          data: (PatientNote? note) {
            final String noteText = note?.noteText ?? '';
            final bool hasNotes = noteText.isNotEmpty;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  hasNotes ? noteText : 'No visit notes recorded.',
                  style: AppTextStyles.body.copyWith(
                    color: hasNotes ? AppColors.textPrimary : AppColors.textMuted,
                    fontStyle: hasNotes ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
                if (userRole == UserRole.doctor || userRole == UserRole.superAdmin) ...[
                  if (userRole == UserRole.superAdmin ||
                      activeDoctors.any((d) => d.doctor.id == ref.read(currentUserProvider).value?.id)) ...[
                    const SizedBox(height: AppSizes.p12),
                    AppButton(
                      labelText: 'Edit Visit Notes',
                      onPressed: () => context.push(
                        AppRoutes.addVisitNotes.replaceAll(':id', appointment.id),
                      ),
                      variant: AppButtonVariant.primary,
                    ),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
