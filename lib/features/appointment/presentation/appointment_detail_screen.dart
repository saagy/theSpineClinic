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
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_status_banner.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/delete_appointment_button.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_notes_card.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_schedule_card.dart';
import 'package:spine_clinic_app/shared/widgets/app_back_button.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';

/// Screen displaying the full detail view for a single appointment.
class AppointmentDetailScreen extends ConsumerWidget {
  const AppointmentDetailScreen({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AppointmentDetailState> detailAsync =
        ref.watch(appointmentDetailControllerProvider(appointmentId));
    final detailState = detailAsync.value;
    final user = ref.watch(currentUserProvider).value;
    final bool showEdit = detailState != null && user != null;
    final bool showDelete = detailState != null &&
        user != null &&
        user.role != UserRole.doctor &&
        (detailState.appointment.status == AppointmentStatus.scheduled ||
         detailState.appointment.status == AppointmentStatus.cancelled);
    final String? patientName = detailState?.patient.fullName;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        leading: const AppBackButton(),
        centerTitle: false,
        title: patientName != null
            ? Text(
                patientName,
                style: AppTextStyles.headingSmall.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : const SizedBox.shrink(),
        actions: [
          if (showEdit)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
              onPressed: () {
                context.push(
                  AppRoutes.editAppointment.replaceAll(':id', detailState.appointment.id),
                );
              },
              tooltip: AppStrings.editDetails,
            ),
          if (showDelete)
            _DetailOverflowButton(
              appointment: detailState.appointment,
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

/// Overflow menu for Delete Appointment.
class _DetailOverflowButton extends ConsumerWidget {
  const _DetailOverflowButton({
    required this.appointment,
  });
  final dynamic appointment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
      padding: const EdgeInsets.only(right: AppSizes.p8),
      constraints: const BoxConstraints(),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.r12),
      ),
      elevation: 1,
      position: PopupMenuPosition.under,
      onSelected: (value) async {
        if (value == 'delete') {
          await deleteAppointmentWithConfirmation(context, ref, appointment);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          value: 'delete',
          height: AppSizes.buttonHeightSmall,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delete_outline_rounded,
                  size: 18, color: AppColors.error),
              const SizedBox(width: AppSizes.p8),
              Text(AppStrings.deleteAppointment,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

/// Data-state body with flat segments and pinned bottom actions.
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
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(appointmentDetailControllerProvider(state.appointment.id));
              try {
                await ref.read(
                  appointmentDetailControllerProvider(state.appointment.id).future,
                );
              } catch (_) {}
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppointmentDetailHeader(
                    appointment: state.appointment,
                    patient: state.patient,
                  ).animate().fadeIn(duration: 300.ms),
                  AppointmentStatusBanner(status: state.appointment.status),
                  const SizedBox(height: AppSizes.p8),
                  AppointmentScheduleCard(appointment: state.appointment),
                  AppointmentDoctorsSection(
                    activeDoctors: state.activeDoctors,
                    inactiveDoctors: state.inactiveDoctors,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
                    child: AppointmentNotesCard(
                      appointmentId: state.appointment.id,
                      patientId: state.appointment.patientId,
                    ),
                  ),
                  const SizedBox(height: AppSizes.p24),
                ],
              ),
            ),
          ),
        ),
        if (hasActions)
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.p24, AppSizes.p16, AppSizes.p24, AppSizes.p16),
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
