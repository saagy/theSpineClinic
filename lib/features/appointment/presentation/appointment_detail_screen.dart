/// Full detail view for a single appointment.
///
/// Handles four states: loading, error, empty, and data.
/// Delegates to extracted sub-widgets for header, doctors, and actions.
///
/// Rule 9 — four strict UI states handled via AsyncValue.when.
/// Rule 1 — under 200 lines by delegating to sub-widgets.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_detail_controller.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_action_buttons.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_detail_header.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_doctors_section.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_notes_card.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/delete_appointment_button.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_schedule_card.dart';
import 'package:spine_clinic_app/shared/widgets/app_back_button.dart';

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
    final detailState = detailAsync.value;
    final user = ref.watch(currentUserProvider).value;
    final bool showEdit = detailState != null && user != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.appointmentDetails,
          style: AppTextStyles.headingSmall,
        ),
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        leading: const AppBackButton(),
        actions: [
          if (showEdit)
            Padding(
              padding: const EdgeInsets.only(right: AppSizes.p16),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary.withAlpha(25),
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.p12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.r12),
                  ),
                ),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => context.push(
                  AppRoutes.editAppointment.replaceAll(':id', appointmentId),
                ),
              ),
            ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSizes.p16),
          child: SkeletonTileList(count: 5),
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

/// Data-state body with three cards and pinned bottom actions.
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

    final bool hasActions = state.appointment.status == AppointmentStatus.scheduled ||
        state.appointment.status == AppointmentStatus.checkedIn ||
        state.appointment.status == AppointmentStatus.cancelled;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppointmentDetailHeader(
                  appointment: state.appointment,
                  patient: state.patient,
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: AppSizes.p16),
                // ── Card 1: Schedule ──
                AppointmentScheduleCard(appointment: state.appointment),
                const SizedBox(height: AppSizes.p16),
                // ── Card 2: Care Team ──
                AppointmentDoctorsSection(
                  activeDoctors: state.activeDoctors,
                  inactiveDoctors: state.inactiveDoctors,
                ),
                const SizedBox(height: AppSizes.p16),
                // ── Card 3: Clinical Notes ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
                  child: AppointmentNotesCard(
                    appointmentId: state.appointment.id,
                    patientId: state.appointment.patientId,
                  ),
                ),
                if (userRole != UserRole.doctor) ...[
                  const SizedBox(height: AppSizes.p24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
                    child: DeleteAppointmentButton(appointment: state.appointment),
                  ),
                ],
                const SizedBox(height: AppSizes.p24),
              ],
            ),
          ),
        ),
        // ── Pinned bottom actions ──
        if (hasActions)
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.p24, AppSizes.p12, AppSizes.p24, AppSizes.p12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                    top: BorderSide(color: AppColors.border, width: 0.5)),
              ),
              child: AppointmentActionButtons(
                appointment: state.appointment,
                userRole: userRole,
              ),
            ),
          ),
      ],
    );
  }
}


