library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_actions_sheet.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_badge.dart';
import 'package:spine_clinic_app/shared/widgets/data_list_tile.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

/// Screen displaying today's appointments dashboard list.
class HomeScreen extends ConsumerWidget {
  /// Creates a [HomeScreen].
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(todayAppointmentsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(todayAppointmentsProvider.notifier).refreshSchedule(),
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: appointmentsAsync.when(
        data: (appointments) {
          if (appointments.isEmpty) {
            return const CustomScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  child: EmptyState(
                    message: AppStrings.noAppointments,
                    icon: Icons.calendar_today_rounded,
                  ),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDateHeader(appointments.length),
              Expanded(
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    return _AppointmentRow(appointment: appointments[index]);
                  },
                ),
              ),
            ],
          );
        },
        error: (err, stack) => ErrorView(
          exception: err is AppException ? err : AppException.fromSupabaseException(err),
          onRetry: () => ref.read(todayAppointmentsProvider.notifier).refreshSchedule(),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildDateHeader(int count) {
    final String dateStr = DateFormat('E MMM dd').format(DateTime.now());
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p24,
        AppSizes.p24,
        AppSizes.p24,
        AppSizes.p16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today, $dateStr',
                style: AppTextStyles.bodySecondary,
              ),
              const SizedBox(height: AppSizes.p4),
              Text(
                AppStrings.appointments,
                style: AppTextStyles.headingLarge,
              ),
            ],
          ),
          AppBadge(
            label: count.toString(),
            textColor: AppColors.primary,
            backgroundColor: AppColors.primaryLight,
          ),
        ],
      ),
    );
  }
}

class _AppointmentRow extends ConsumerWidget {
  const _AppointmentRow({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientAsync = ref.watch(patientDetailProvider(appointment.patientId));
    final String title = patientAsync.when(
      data: (patient) => patient.fullName,
      loading: () => 'Loading...',
      error: (_, __) => 'Unknown Patient',
    );

    return DataListTile(
      title: title,
      subtitle: appointment.type.displayLabel,
      leading: Padding(
        padding: const EdgeInsets.only(right: AppSizes.p4),
        child: Text(
          Formatters.formatTime(appointment.scheduledAt),
          style: AppTextStyles.bodyBold.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBadge(
            label: appointment.type.displayLabel,
            textColor: appointment.type.textColor,
            backgroundColor: appointment.type.backgroundColor,
          ),
          const SizedBox(width: AppSizes.p8),
          AppBadge(
            label: appointment.status.displayLabel,
            textColor: appointment.status.textColor,
            backgroundColor: appointment.status.backgroundColor,
          ),
        ],
      ),
      onTap: () => showModalBottomSheet(
        context: context,
        builder: (_) => AppointmentActionsSheet(appointment: appointment),
      ),
    );
  }
}

