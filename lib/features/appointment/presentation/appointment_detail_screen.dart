/// Full detail view for a single appointment.
///
/// Handles four states: loading, error, empty, and data.
/// Delegates to extracted sub-widgets for header, doctors, and actions.
///
/// Rule 9 — four strict UI states handled via AsyncValue.when.
/// Rule 1 — under 200 lines by delegating to sub-widgets.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_detail_controller.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_action_buttons.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_detail_header.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_doctors_section.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/info_row.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';

/// Screen displaying the full detail view for a single appointment.
class AppointmentDetailScreen extends ConsumerWidget {
  /// Creates an [AppointmentDetailScreen].
  const AppointmentDetailScreen({super.key, required this.appointmentId});

  /// The unique ID of the appointment to display.
  final String appointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AppointmentDetailState> detailAsync =
        ref.watch(appointmentDetailControllerProvider(appointmentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.appointmentDetails,
          style: AppTextStyles.headingSmall,
        ),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: const BackButton(),
      ),
      body: detailAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (Object error, StackTrace stack) => ErrorView(
          exception: error is AppException
              ? error
              : AppException.fromSupabaseException(error),
          onRetry: () => ref.invalidate(
            appointmentDetailControllerProvider(appointmentId),
          ),
        ),
        data: (AppointmentDetailState state) =>
            _AppointmentDetailBody(state: state),
      ),
    );
  }
}

/// Data-state body rendering all appointment detail sections.
class _AppointmentDetailBody extends ConsumerWidget {
  const _AppointmentDetailBody({required this.state});

  final AppointmentDetailState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRole = ref.watch(currentUserProvider).value?.role;
    if (userRole == null) {
      return const EmptyState(
        message: AppStrings.appointmentNotFound,
        icon: Icons.event_busy_rounded,
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: patient name, clinic badge, status badge
          AppointmentDetailHeader(
            appointment: state.appointment,
            patient: state.patient,
          ),

          // Details card: date, time, type, use package
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
            child: SectionCard(
              child: Column(
                children: [
                  InfoRow(
                    label: AppStrings.date,
                    value: Formatters.formatDateMedium(
                      state.appointment.scheduledAt,
                    ),
                  ),
                  InfoRow(
                    label: AppStrings.time,
                    value: Formatters.formatTime(
                      state.appointment.scheduledAt,
                    ),
                  ),
                  InfoRow(
                    label: AppStrings.type,
                    value: state.appointment.type.displayLabel,
                  ),
                  InfoRow(
                    label: AppStrings.usePackage,
                    value: state.appointment.usePackage
                        ? AppStrings.yes
                        : AppStrings.no,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSizes.p16),

          // Doctors section: active + inactive audit trail
          AppointmentDoctorsSection(
            activeDoctors: state.activeDoctors,
            inactiveDoctors: state.inactiveDoctors,
          ),

          const SizedBox(height: AppSizes.p16),

          // Notes Section Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
            child: SectionCard(
              title: AppStrings.notes,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    state.appointment.notes?.isNotEmpty == true
                        ? state.appointment.notes!
                        : 'No visit notes recorded.',
                    style: AppTextStyles.body.copyWith(
                      color: state.appointment.notes?.isNotEmpty == true
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                      fontStyle: state.appointment.notes?.isNotEmpty == true
                          ? FontStyle.normal
                          : FontStyle.italic,
                    ),
                  ),
                  if ((userRole == UserRole.doctor ||
                          userRole == UserRole.superAdmin) &&
                      (state.appointment.status == AppointmentStatus.checkedIn ||
                          state.appointment.status == AppointmentStatus.completed)) ...[
                    if (userRole == UserRole.superAdmin ||
                        state.activeDoctors.any(
                            (d) => d.doctor.id == ref.read(currentUserProvider).value?.id)) ...[
                      const SizedBox(height: AppSizes.p12),
                      AppButton(
                        labelText: 'Edit Visit Notes',
                        onPressed: () => context.push(
                          AppRoutes.addVisitNotes.replaceAll(':id', state.appointment.id),
                        ),
                        variant: AppButtonVariant.secondary,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSizes.p16),

          // Role-guarded action buttons
          AppointmentActionButtons(
            appointment: state.appointment,
            userRole: userRole,
          ),

          const SizedBox(height: AppSizes.p32),
        ],
      ),
    );
  }
}
