import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/admin/presentation/branch_providers.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_actions_trailing.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_badge.dart';
import 'package:spine_clinic_app/shared/widgets/data_list_tile.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

/// Screen displaying today's appointments dashboard list.
/// Rule 1 — strictly under 200 lines.
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
        data: (appointments) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDateHeader(context, ref, appointments.length),
            Expanded(
              child: appointments.isEmpty
                  ? const Center(
                      child: EmptyState(
                        message: AppStrings.noAppointments,
                        icon: Icons.calendar_today_rounded,
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: appointments.length,
                      itemBuilder: (context, index) {
                        return _AppointmentRow(appointment: appointments[index]);
                      },
                    ),
            ),
          ],
        ),
        error: (err, stack) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDateHeader(context, ref, 0),
            Expanded(
              child: ErrorView(
                exception: err is AppException ? err : AppException.fromSupabaseException(err),
                onRetry: () => ref.read(todayAppointmentsProvider.notifier).refreshSchedule(),
              ),
            ),
          ],
        ),
        loading: () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDateHeader(context, ref, 0),
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context, WidgetRef ref, int count) {
    final String dateStr = DateFormat('E MMM dd').format(DateTime.now());
    final activeBranch = ref.watch(activeBranchProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.p24, AppSizes.p24, AppSizes.p24, AppSizes.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.todayWithDate(dateStr), style: AppTextStyles.bodySecondary),
                  const SizedBox(height: AppSizes.p4),
                  Text(AppStrings.appointments, style: AppTextStyles.headingLarge),
                ],
              ),
              AppBadge(
                label: count.toString(),
                textColor: AppColors.primary,
                backgroundColor: AppColors.primaryLight,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p12),
          Row(
            children: ClinicLocation.values.map((branch) {
              final isSelected = activeBranch == branch;
              return Padding(
                padding: const EdgeInsets.only(right: AppSizes.p8),
                child: ChoiceChip(
                  label: Text(branch.displayLabel),
                  selected: isSelected,
                  selectedColor: AppColors.primaryLight,
                  labelStyle: AppTextStyles.captionMedium.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(AppSizes.r6)),
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: AppSizes.borderWidth,
                  ),
                  showCheckmark: false,
                  onSelected: (val) {
                    if (val) {
                      ref.read(activeBranchProvider.notifier).setBranch(branch);
                    }
                  },
                ),
              );
            }).toList(),
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
          Formatters.formatTime(appointment.scheduledAt.toLocal()),
          style: AppTextStyles.bodyBold.copyWith(color: AppColors.textPrimary),
        ),
      ),
      trailing: AppointmentActionsTrailing(appointment: appointment),
      onTap: () => context.push(
        AppRoutes.appointmentDetail.replaceAll(':id', appointment.id),
      ),
    );
  }
}
