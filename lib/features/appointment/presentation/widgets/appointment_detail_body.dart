/// Body content and layout for the appointment detail screen.
///
/// Rule 1 — keep files under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_detail_controller.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_action_buttons.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_detail_header.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_doctors_section.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_info_card.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_notes_card.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_status_banner.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';

/// Data-state body with flat document layout and pinned bottom actions.
class AppointmentDetailBody extends ConsumerWidget {
  const AppointmentDetailBody({
    super.key,
    required this.state,
    required this.scrollController,
  });

  final AppointmentDetailState state;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userRole = ref.watch(currentUserProvider).value?.role;
    if (userRole == null) {
      return const EmptyState(
        message: AppStrings.appointmentNotFound,
        icon: Icons.event_busy_rounded,
      );
    }

    final bool hasActions =
        state.appointment.status == AppointmentStatus.scheduled ||
        state.appointment.status == AppointmentStatus.checkedIn ||
        state.appointment.status == AppointmentStatus.cancelled;

    final otherAppointmentsAsync = ref.watch(
      patientAppointmentsProvider(state.appointment.patientId),
    );

    final DateTime currentDay = DateUtils.dateOnly(
      state.appointment.scheduledAt.toLocal(),
    );
    final String currentId = state.appointment.id;

    final List<Appointment> linkedAppointments =
        otherAppointmentsAsync.maybeWhen(
      data: (list) {
        return list.where((appt) {
          final day = DateUtils.dateOnly(appt.scheduledAt.toLocal());
          return appt.id != currentId &&
              day == currentDay &&
              appt.status != AppointmentStatus.cancelled;
        }).toList();
      },
      orElse: () => const <Appointment>[],
    );

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(
                appointmentDetailControllerProvider(state.appointment.id),
              );
              try {
                await ref.read(
                  appointmentDetailControllerProvider(
                    state.appointment.id,
                  ).future,
                );
              } catch (_) {}
            },
            child: SingleChildScrollView(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppointmentDetailHeader(
                    patient: state.patient,
                  ).animate().fadeIn(duration: 300.ms),
                  AppointmentStatusBanner(
                    status: state.appointment.status,
                    scheduledAt: state.appointment.scheduledAt,
                  ),
                  AppointmentInfoCard(
                    appointment: state.appointment,
                    linkedAppointments: linkedAppointments,
                  ),
                  AppointmentNotesCard(
                    appointmentId: state.appointment.id,
                    patientId: state.appointment.patientId,
                  ),
                  AppointmentDoctorsSection(
                    activeDoctors: state.activeDoctors,
                    inactiveDoctors: state.inactiveDoctors,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasActions)
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.p16,
                AppSizes.p12,
                AppSizes.p16,
                AppSizes.p12,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                    width: 0.5,
                  ),
                ),
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
