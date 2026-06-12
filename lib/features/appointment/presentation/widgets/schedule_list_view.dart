import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/presentation/my_schedule_controller.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/shared/widgets/data_list_tile.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_actions_trailing.dart';

/// Renders the chronological (Today) or grouped (Week) calendar agenda.
class ScheduleListView extends StatelessWidget {
  /// Creates a [ScheduleListView].
  const ScheduleListView({
    super.key,
    required this.state,
    required this.onRetry,
    required this.onRefresh,
  });

  /// The async state containing the filtered items list and horizon.
  final AsyncValue<MyScheduleState> state;

  /// Triggered on retry when in error state.
  final VoidCallback onRetry;

  /// Triggered on pull-to-refresh.
  final RefreshCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return state.when(
      data: (scheduleState) {
        final items = scheduleState.items;
        if (items.isEmpty) {
          final String emptyMsg = scheduleState.horizon == MyScheduleHorizon.today
              ? 'No appointments scheduled for today'
              : 'No appointments this week';
          return RefreshIndicator(
            onRefresh: onRefresh,
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  child: EmptyState(
                    message: emptyMsg,
                    icon: Icons.calendar_today_rounded,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          child: scheduleState.horizon == MyScheduleHorizon.today
              ? _buildTodayView(context, items)
              : _buildWeekView(context, items),
        );
      },
      error: (error, stack) {
        final appException = error is AppException
            ? error
            : AppException.fromSupabaseException(error);
        return ErrorView(
          exception: appException,
          onRetry: onRetry,
        );
      },
      loading: () => _buildSkeleton(),
    );
  }

  Widget _buildTodayView(BuildContext context, List<DoctorScheduleItem> items) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildRow(context, items[index]);
      },
    );
  }

  Widget _buildWeekView(BuildContext context, List<DoctorScheduleItem> items) {
    final Map<DateTime, List<DoctorScheduleItem>> grouped = {};
    for (final item in items) {
      final date = item.appointment.scheduledAt.toLocal();
      final dayKey = DateTime(date.year, date.month, date.day);
      grouped.putIfAbsent(dayKey, () => []).add(item);
    }

    final sortedDates = grouped.keys.toList()..sort();

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dayItems = grouped[date]!;
        final String dateHeader = DateFormat('EEEE, MMM dd').format(date);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSizes.p16, AppSizes.p16, AppSizes.p16, AppSizes.p8),
              child: Text(
                dateHeader,
                style: AppTextStyles.bodyBold.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
            ...dayItems.map((item) => _buildRow(context, item)),
          ],
        );
      },
    );
  }

  Widget _buildRow(BuildContext context, DoctorScheduleItem item) {
    final appointment = item.appointment;
    final appointmentDoctor = item.appointmentDoctor;

    final String? subtitle = appointmentDoctor.isReplacement
        ? 'Covering ${item.replacedDoctor?.fullName ?? AppStrings.unknownDoctorFallback}'
        : null;

    return DataListTile(
      title: item.patient.fullName,
      subtitle: subtitle,
      leading: Padding(
        padding: const EdgeInsets.only(right: AppSizes.p4),
        child: Text(
          Formatters.formatTime(appointment.scheduledAt.toLocal()),
          style: AppTextStyles.bodyBold.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
      trailing: AppointmentActionsTrailing(appointment: appointment),
      onTap: () {
        context.push(
          AppRoutes.appointmentDetail.replaceAll(':id', appointment.id),
        );
      },
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p12,
            vertical: AppSizes.p8,
          ),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.border.withAlpha(50),
              borderRadius: BorderRadius.circular(AppSizes.r8),
            ),
          ),
        );
      },
    );
  }
}
