import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/admin/data/analytics_dtos.dart';
import 'package:spine_clinic_app/features/admin/presentation/analytics_providers.dart';
import 'package:spine_clinic_app/features/admin/presentation/widgets/breakdown_list_card.dart';
import 'package:spine_clinic_app/features/admin/presentation/widgets/stats_metric_card.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

/// Section displaying appointment KPIs: volume, rates, status breakdowns, busiest days.
/// Loads independently from other analytics sections.
class AppointmentsSummarySection extends ConsumerWidget {
  const AppointmentsSummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(appointmentSummaryProvider);

    return asyncData.when(
      loading: () => _buildLoading(),
      error: (error, _) => ErrorView(
        exception: error is AppException ? error : AppException.fromSupabaseException(error),
        onRetry: () => ref.invalidate(appointmentSummaryProvider),
      ),
      data: (data) => _buildData(data),
    );
  }

  Widget _buildLoading() {
    return Column(
      children: [
        Row(
          children: const [
            Expanded(child: StatsMetricCard(title: '', value: '', icon: Icons.calendar_today_rounded, isLoading: true)),
            SizedBox(width: AppSizes.p12),
            Expanded(child: StatsMetricCard(title: '', value: '', icon: Icons.check_circle_rounded, isLoading: true)),
          ],
        ),
        const SizedBox(height: AppSizes.p12),
        Row(
          children: const [
            Expanded(child: StatsMetricCard(title: '', value: '', icon: Icons.cancel_rounded, isLoading: true)),
            SizedBox(width: AppSizes.p12),
            Expanded(child: StatsMetricCard(title: '', value: '', icon: Icons.today_rounded, isLoading: true)),
          ],
        ),
      ],
    );
  }

  Widget _buildData(AppointmentSummary data) {
    final bool isEmpty = data.totalAppointments == 0;

    if (isEmpty) {
      return const EmptyState(message: AppStrings.noAppointmentData, icon: Icons.calendar_today_rounded);
    }

    final String compRate = '${(data.completionRate * 100).toStringAsFixed(0)}%';
    final String cancRate = '${(data.cancellationRate * 100).toStringAsFixed(0)}%';
    final String busiestDay = _findBusiestDay(data.byDayOfWeek);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: StatsMetricCard(title: AppStrings.totalAppointments, value: '${data.totalAppointments}', icon: Icons.calendar_today_rounded)),
            const SizedBox(width: AppSizes.p12),
            Expanded(child: StatsMetricCard(title: AppStrings.completionRate, value: compRate, icon: Icons.check_circle_rounded, subtitle: AppStrings.sessionsCompleted)),
          ],
        ),
        const SizedBox(height: AppSizes.p12),
        Row(
          children: [
            Expanded(child: StatsMetricCard(title: AppStrings.cancellationRate, value: cancRate, icon: Icons.cancel_rounded)),
            const SizedBox(width: AppSizes.p12),
            Expanded(child: StatsMetricCard(title: AppStrings.busiestDay, value: busiestDay, icon: Icons.today_rounded)),
          ],
        ),
        const SizedBox(height: AppSizes.p16),
        BreakdownListCard(title: AppStrings.appointmentsByStatus, data: data.byStatus, barColor: AppColors.success),
        const SizedBox(height: AppSizes.p16),
        BreakdownListCard(title: AppStrings.appointmentsByDay, data: data.byDayOfWeek, barColor: AppColors.info),
      ],
    );
  }

  String _findBusiestDay(Map<String, int> byDow) {
    if (byDow.isEmpty) return '—';
    final entry = byDow.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return entry.value > 0 ? entry.key : '—';
  }
}
