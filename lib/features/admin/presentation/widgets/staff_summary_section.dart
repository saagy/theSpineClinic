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
import 'package:spine_clinic_app/shared/widgets/section_card.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// Section displaying staff KPIs: appointments/doctor, completion rates, top performers.
/// Loads independently from other analytics sections.
class StaffSummarySection extends ConsumerWidget {
  const StaffSummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(staffSummaryProvider);

    return asyncData.when(
      loading: () => _buildLoading(),
      error: (error, _) => ErrorView(
        exception: error is AppException ? error : AppException.fromSupabaseException(error),
        onRetry: () => ref.invalidate(staffSummaryProvider),
      ),
      data: (data) => _buildData(data),
    );
  }

  Widget _buildLoading() {
    return Column(
      children: [
        Row(
          children: const [
            Expanded(child: StatsMetricCard(title: '', value: '', icon: Icons.people_alt_rounded, isLoading: true)),
            SizedBox(width: AppSizes.p12),
            Expanded(child: StatsMetricCard(title: '', value: '', icon: Icons.person_add_rounded, isLoading: true)),
          ],
        ),
        const SizedBox(height: AppSizes.p16),
        _skeletonSection(),
      ],
    );
  }

  Widget _skeletonSection() {
    return SectionCard(
      title: AppStrings.topPerformingDoctors,
      child: Column(
        children: List.generate(3, (_) => Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.p8),
          child: Container(
            height: AppSizes.skeletonLabelHeight,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.all(Radius.circular(AppSizes.r4)),
            ),
          ),
        )),
      ),
    );
  }

  Widget _buildData(StaffSummary data) {
    final bool isEmpty = data.appointmentsPerDoctor.isEmpty && data.newStaffInPeriod == 0;

    if (isEmpty) {
      return const EmptyState(message: AppStrings.noStaffData, icon: Icons.people_alt_rounded);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: StatsMetricCard(title: AppStrings.activeDoctorsCount, value: '${data.appointmentsPerDoctor.length}', icon: Icons.people_alt_rounded)),
            const SizedBox(width: AppSizes.p12),
            Expanded(child: StatsMetricCard(title: AppStrings.newStaffInPeriod, value: '${data.newStaffInPeriod}', icon: Icons.person_add_rounded)),
          ],
        ),
        const SizedBox(height: AppSizes.p16),
        if (data.topDoctors.isNotEmpty) _buildTopDoctors(data),
        const SizedBox(height: AppSizes.p16),
        if (data.appointmentsPerDoctor.isNotEmpty)
          BreakdownListCard(title: AppStrings.appointmentsPerDoctor, data: data.appointmentsPerDoctor, barColor: AppColors.primary),
      ],
    );
  }

  Widget _buildTopDoctors(StaffSummary data) {
    return SectionCard(
      title: AppStrings.topPerformingDoctors,
      child: Column(
        children: data.topDoctors.asMap().entries.map((entry) {
          final String name = entry.value;
          final int count = data.appointmentsPerDoctor[name] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.p8),
            child: Row(
              children: [
                Container(
                  width: AppSizes.iconDefault,
                  height: AppSizes.iconDefault,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r4)),
                  ),
                  child: Center(
                    child: Text('${entry.key + 1}', style: AppTextStyles.captionBold.copyWith(color: AppColors.primary)),
                  ),
                ),
                const SizedBox(width: AppSizes.p12),
                Expanded(child: Text(name, style: AppTextStyles.bodyBold.copyWith(color: AppColors.textPrimary))),
                Text('$count ${AppStrings.sessionsCompleted.toLowerCase()}', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
