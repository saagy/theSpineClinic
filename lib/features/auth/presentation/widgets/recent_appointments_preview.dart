/// Shows up to the last 5 appointments for a doctor.
///
/// Uses a scoped [FutureProvider.family] so the schedule data is
/// reactive and refetches when the provider is invalidated.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/shared/widgets/data_list_tile.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';

/// Scoped future provider that resolves a doctor's schedule and unwraps
/// the [Result] so the UI only sees success or throws on failure.
final _doctorSchedulePreviewProvider =
    FutureProvider.family<List<DoctorScheduleItem>, String>((ref, doctorId) async {
      final repo = ref.watch(appointmentRepositoryProvider);
      final result = await repo.getDoctorSchedule(doctorId);
      return result.when(
        success: (data) => data,
        failure: (error) => throw error,
      );
    });

/// A preview widget showing the last 5 appointments for a doctor.
class RecentAppointmentsPreview extends ConsumerWidget {
  /// Creates a [RecentAppointmentsPreview].
  const RecentAppointmentsPreview({super.key, required this.doctorId});

  /// The staff ID of the doctor whose appointments to preview.
  final String doctorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(_doctorSchedulePreviewProvider(doctorId));

    return scheduleAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.p24),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (_, __) => const EmptyState(
        message: AppStrings.noHistoricAppointments,
        icon: Icons.history_rounded,
      ),
      data: (items) {
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.p16),
            child: EmptyState(
              message: AppStrings.noHistoricAppointments,
              icon: Icons.history_rounded,
            ),
          );
        }

        final preview = items.take(5).toList();

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: preview.length,
          separatorBuilder: (_, __) => const Divider(
            height: 1,
            color: AppColors.border,
          ),
          itemBuilder: (_, index) {
            final item = preview[index];
            return DataListTile(
              title: item.patient.fullName,
              subtitle:
                  '${item.appointment.type.displayLabel} · ${Formatters.formatDateMedium(item.appointment.scheduledAt.toLocal())}',
              transparent: true,
              onTap: () => context.push(
                AppRoutes.appointmentDetail.replaceAll(':id', item.appointment.id),
              ),
            );
          },
        );
      },
    );
  }
}
