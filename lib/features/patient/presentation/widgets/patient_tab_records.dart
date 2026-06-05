import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/shared/widgets/data_list_tile.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

/// Renders completed medical visit logs and notes for a patient.
class PatientTabRecords extends ConsumerWidget {
  /// Creates a [PatientTabRecords].
  const PatientTabRecords({super.key, required this.patient});

  /// The patient entity.
  final Patient patient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Appointment>> appointmentsAsync =
        ref.watch(patientAppointmentsProvider(patient.id));

    return appointmentsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (Object err, StackTrace stack) => ErrorView(
        exception: err is AppException
            ? err
            : AppException.fromSupabaseException(err),
        onRetry: () => ref.invalidate(patientAppointmentsProvider(patient.id)),
      ),
      data: (List<Appointment> appointments) {
        // Filter only completed appointments representing clinical visits (Phase 8 Part 2 §4)
        final List<Appointment> completedVisits = appointments
            .where((a) => a.status == AppointmentStatus.completed)
            .toList();

        if (completedVisits.isEmpty) {
          return const EmptyState(
            message: 'No visit notes recorded yet',
            icon: Icons.history_edu_rounded,
          );
        }

        return ListView.builder(
          itemCount: completedVisits.length,
          padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
          itemBuilder: (context, index) {
            final Appointment visit = completedVisits[index];
            return DataListTile(
              title: Formatters.formatDateMedium(visit.scheduledAt),
              subtitle: visit.notes?.isNotEmpty == true
                  ? visit.notes!
                  : 'No visit notes recorded.',
              leading: const Icon(
                Icons.article_outlined,
                color: AppColors.textSecondary,
              ),
              onTap: () => context.push(
                AppRoutes.visitDetail.replaceAll(':id', visit.id),
              ),
            );
          },
        );
      },
    );
  }
}
