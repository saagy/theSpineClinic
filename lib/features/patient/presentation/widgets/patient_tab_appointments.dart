import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_appointment_card.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

/// Renders a chronological list of appointments for a patient.
class PatientTabAppointments extends ConsumerWidget {
  /// Creates a [PatientTabAppointments].
  const PatientTabAppointments({super.key, required this.patient});

  /// The patient entity.
  final Patient patient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final isDoctor = user?.role == UserRole.doctor;
    final appointmentsAsync = ref.watch(patientAppointmentsProvider(patient.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isDoctor) ...[
          Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: AppButton(
              labelText: AppStrings.bookAppointment,
              onPressed: () {
                context.push('${AppRoutes.newAppointment}?patientId=${patient.id}');
              },
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.border),
        ],
        Expanded(
          child: appointmentsAsync.when(
            data: (appointments) {
              if (appointments.isEmpty) {
                return const EmptyState(
                  message: AppStrings.noAppointments,
                  icon: Icons.calendar_today_rounded,
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(patientAppointmentsProvider(patient.id));
                },
                color: AppColors.primary,
                backgroundColor: AppColors.surface,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: AppSizes.p16),
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = appointments[index];
                    final item = AppointmentWithPatient(
                      appointment: appointment, patient: patient,
                    );
                    return ReceptionistAppointmentCard(
                      item: item,
                      showMenu: true,
                      showDate: true,
                      onStatusChanged: () =>
                          ref.invalidate(patientAppointmentsProvider(patient.id)),
                    ).animate().fadeIn(
                          duration: 250.ms,
                          delay: (index * 30).ms,
                        );
                  },
                ),
              );
            },
            loading: () => const SkeletonTileList(count: 4),
            error: (error, _) {
              return ErrorView(
                exception: error is AppException
                    ? error
                    : const UnknownException(
                        message: AppStrings.errorDatabaseQueryFailed,
                      ),
                onRetry: () => ref.invalidate(patientAppointmentsProvider(patient.id)),
              );
            },
          ),
        ),
      ],
    );
  }
}
