import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_badge_colors.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/visit_detail_controller.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_badge.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/info_row.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';
import 'package:spine_clinic_app/shared/widgets/app_back_button.dart';

/// Pushed full-screen route for viewing checked-in clinical visit notes.
class VisitDetailScreen extends ConsumerWidget {
  /// Creates a [VisitDetailScreen].
  const VisitDetailScreen({super.key, required this.appointmentId});

  /// The appointment ID of the visit to detail.
  final String appointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(visitDetailControllerProvider(appointmentId));
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppStrings.visitDetails, style: AppTextStyles.headingSmall),
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surface.withAlpha(0),
        leading: const AppBackButton(),
        actions: [
          stateAsync.maybeWhen(
            data: (state) => state.canEditNotes
                ? IconButton(
                    icon: Icon(Icons.edit_note_rounded),
                    tooltip: AppStrings.editNotesTooltip,
                    onPressed: () => context.push(
                      AppRoutes.addVisitNotes.replaceAll(':id', appointmentId),
                    ),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: stateAsync.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: cs.primary)),
        error: (err, stack) => ErrorView(
          exception: err is AppException
              ? err
              : AppException.fromSupabaseException(err),
          onRetry: () =>
              ref.invalidate(visitDetailControllerProvider(appointmentId)),
        ),
        data: (state) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.p24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoSection(context, ref, state),
              const SizedBox(height: AppSizes.p16),
              _buildDoctorsSection(context, state),
              const SizedBox(height: AppSizes.p16),
              _buildNotesSection(context, state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    WidgetRef ref,
    VisitDetailState state,
  ) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppointmentBadgeColors typeBadge = state.appointment.type.badgeColors(
      context,
    );
    final AppointmentBadgeColors statusBadge = state.appointment.status
        .badgeColors(context);
    final user = ref.watch(currentUserProvider).value;
    final isDoctor = user?.role == UserRole.doctor;
    final canAccessAsync = isDoctor
        ? ref.watch(canAccessPatientProvider(state.patient.id))
        : const AsyncValue.data(true);
    final bool canAccess = canAccessAsync.value ?? !isDoctor;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              if (!canAccess) {
                AppSnackbar.show(
                  context,
                  message: AppStrings.errorDatabasePermissionDenied,
                  variant: AppSnackbarVariant.error,
                );
                return;
              }
              context.push(
                AppRoutes.patientDetail.replaceAll(':id', state.patient.id),
              );
            },
            borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r4)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.p4),
              child: Row(
                children: [
                  Icon(
                    Icons.person_rounded,
                    color: cs.primary,
                    size: AppSizes.iconDefault,
                  ),
                  const SizedBox(width: AppSizes.p8),
                  Expanded(
                    child: Text(
                      state.patient.fullName,
                      style: AppTextStyles.bodyBold.copyWith(
                        color: cs.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: AppSizes.p24),
          InfoRow(
            label: AppStrings.date,
            value: Formatters.formatDateMedium(state.appointment.scheduledAt),
          ),
          InfoRow(
            label: AppStrings.time,
            value: Formatters.formatTime(state.appointment.scheduledAt),
          ),
          const SizedBox(height: AppSizes.p12),
          Row(
            children: [
              AppBadge(
                label: state.appointment.type.displayLabel,
                textColor: typeBadge.textColor,
                backgroundColor: typeBadge.backgroundColor,
              ),
              const SizedBox(width: AppSizes.p8),
              AppBadge(
                label: state.appointment.status.displayLabel,
                textColor: statusBadge.textColor,
                backgroundColor: statusBadge.backgroundColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorsSection(BuildContext context, VisitDetailState state) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ClinicColors clinic = ClinicColors.of(context);

    return SectionCard(
      title: AppStrings.attendingStaff,
      child: state.activeDoctors.isEmpty
          ? Text(
              AppStrings.noStaffAssignedToSession,
              style: AppTextStyles.caption,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: state.activeDoctors.map((docDetail) {
                final bool isActive = docDetail.doctor.isActive;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.p4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.medical_services_outlined,
                        color: cs.onSurfaceVariant,
                        size: AppSizes.iconSmall,
                      ),
                      const SizedBox(width: AppSizes.p8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: AppTextStyles.body,
                            children: [
                              TextSpan(
                                text: docDetail.doctor.fullName,
                                style: AppTextStyles.bodyMedium,
                              ),
                              if (!isActive)
                                TextSpan(
                                  text: ' (${AppStrings.deactivated})',
                                  style: AppTextStyles.caption.copyWith(
                                    color: clinic.warning,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildNotesSection(BuildContext context, VisitDetailState state) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ClinicColors clinic = ClinicColors.of(context);
    final noteText = state.note?.noteText;
    return SectionCard(
      title: 'Clinical Visit Notes',
      child: Text(
        noteText?.isNotEmpty == true
            ? noteText!
            : 'No visit notes recorded for this session.',
        style: AppTextStyles.body.copyWith(
          color: noteText?.isNotEmpty == true ? cs.onSurface : clinic.textMuted,
          fontStyle: noteText?.isNotEmpty == true
              ? FontStyle.normal
              : FontStyle.italic,
        ),
      ),
    );
  }
}
