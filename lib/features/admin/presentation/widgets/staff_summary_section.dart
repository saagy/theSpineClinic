import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/admin/data/analytics_dtos.dart';
import 'package:spine_clinic_app/features/admin/presentation/analytics_providers.dart';
import 'package:spine_clinic_app/features/admin/presentation/widgets/stats_metric_card.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/shared/widgets/app_avatar.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';
import 'package:spine_clinic_app/features/admin/presentation/widgets/doctor_performance_sheet.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';

/// Section displaying staff KPIs: appointments, attendance, and top performers.
/// Loads independently from other analytics sections.
class StaffSummarySection extends ConsumerWidget {
  const StaffSummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(staffSummaryProvider);

    return asyncData.when(
      loading: () => _buildLoading(context),
      error: (error, _) => ErrorView(
        exception: error is AppException
            ? error
            : AppException.fromSupabaseException(error),
        onRetry: () => ref.invalidate(staffSummaryProvider),
      ),
      data: (data) => _buildData(context, data),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Column(
      children: [
        const StatsMetricCard(
          title: '',
          value: '',
          icon: Icons.people_alt_rounded,
          isLoading: true,
        ),
        const SizedBox(height: AppSizes.p16),
        _skeletonSection(context),
      ],
    );
  }

  Widget _skeletonSection(BuildContext context) {
    return SectionCard(
      title: AppStrings.staffPerformance,
      child: Column(
        children: List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.p8),
            child: Container(
              height: AppSizes.skeletonLabelHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppSizes.r4),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildData(BuildContext context, StaffSummary data) {
    if (data.doctorPerformances.isEmpty) {
      return const EmptyState(
        message: AppStrings.noStaffData,
        icon: Icons.people_alt_rounded,
      );
    }

    final ThemeData theme = Theme.of(context);
    final ClinicColors clinicColors = ClinicColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatsMetricCard(
          title: AppStrings.activeDoctorsCount,
          value: '${data.doctorPerformances.length}',
          icon: Icons.people_alt_rounded,
        ),
        const SizedBox(height: AppSizes.p16),
        SectionCard(
          title: AppStrings.staffPerformance,
          child: Column(
            children: data.doctorPerformances.map((perf) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.p12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(AppSizes.r16),
                    ),
                    onTap: () {
                      AppBottomSheet.show(
                        context: context,
                        title: perf.fullName,
                        initialChildSize: 0.8,
                        builder: (context, scrollController) =>
                            DoctorPerformanceSheet(
                              performance: perf,
                              scrollController: scrollController,
                            ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(AppSizes.p16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(AppSizes.r16),
                        ),
                      ),
                      child: Row(
                        children: [
                          AppAvatar(name: perf.fullName, radius: AppSizes.p20),
                          const SizedBox(width: AppSizes.p12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  perf.fullName,
                                  style: AppTextStyles.bodyBold.copyWith(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: AppSizes.p4),
                                Text(
                                  '${AppStrings.activeDays}: ${perf.activeDays}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: clinicColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${perf.checkedInAppointments}/${perf.eligibleAppointments}',
                                style: AppTextStyles.bodyBold.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: AppSizes.p4),
                              Text(
                                AppStrings.sessionsCheckedIn,
                                style: AppTextStyles.caption.copyWith(
                                  color: clinicColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
