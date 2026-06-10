import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/admin/data/admin_repository.dart';
import 'package:spine_clinic_app/features/admin/presentation/reports_controller.dart';
import 'package:spine_clinic_app/features/admin/presentation/widgets/branch_comparison_card.dart';
import 'package:spine_clinic_app/features/admin/presentation/widgets/breakdown_list_card.dart';
import 'package:spine_clinic_app/features/admin/presentation/widgets/reports_filter_bar.dart';
import 'package:spine_clinic_app/features/admin/presentation/widgets/revenue_summary_card.dart';
import 'package:spine_clinic_app/features/admin/presentation/widgets/stats_metric_card.dart';
import 'package:spine_clinic_app/features/admin/presentation/widgets/trend_chart.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

/// Screen displaying clinic statistical analytics and performance reports.
/// Protected by a Super Admin role guard.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUser = ref.watch(currentUserProvider);

    return asyncUser.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: ErrorView(
          exception: error is AppException ? error : const UnknownException(message: AppStrings.errorDatabaseQueryFailed),
          onRetry: () => ref.invalidate(currentUserProvider),
        ),
      ),
      data: (user) {
        if (user == null || user.role != UserRole.superAdmin) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: ErrorView(
              exception: UnknownException(message: AppStrings.errorDatabasePermissionDenied, code: 'security/blocked'),
            ),
          );
        }

        final reportsAsync = ref.watch(reportsDataProvider);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            title: const Text(AppStrings.reportsAndAnalytics),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
          ),
          body: Column(
            children: [
              const ReportsFilterBar(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref.refresh(reportsDataProvider.future),
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  child: reportsAsync.when(
                    data: (data) {
                      final bool hasNoData = data.totalPatients == 0 && data.totalAppointments == 0;
                      if (hasNoData) {
                        return const SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: AppSizes.p40 * 2 + AppSizes.p20),
                              child: EmptyState(message: AppStrings.noData, icon: Icons.bar_chart_rounded),
                            ),
                          ),
                        );
                      }
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppSizes.p16),
                        children: [
                          GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: AppSizes.p12,
                            mainAxisSpacing: AppSizes.p12,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              StatsMetricCard(title: AppStrings.totalPatients, value: data.totalPatients.toString(), icon: Icons.people_alt_rounded),
                              StatsMetricCard(title: AppStrings.newPatients, value: data.newPatients.toString(), icon: Icons.person_add_rounded, subtitle: AppStrings.registeredInPeriod),
                              StatsMetricCard(title: AppStrings.appointmentsCount, value: data.totalAppointments.toString(), icon: Icons.calendar_today_rounded, subtitle: AppStrings.bookedInPeriod),
                              StatsMetricCard(title: AppStrings.activeDoctorsCount, value: data.doctorBreakdown.length.toString(), icon: Icons.medical_services_rounded, subtitle: AppStrings.assignedInPeriod),
                            ],
                          ),
                          const SizedBox(height: AppSizes.p16),
                          RevenueSummaryCard(grossIncome: data.grossIncome, totalPackageBalances: data.totalPackageBalances),
                          const SizedBox(height: AppSizes.p16),
                          BranchComparisonCard(tagamoa: data.tagamoaMetrics, masrElgedida: data.masrElgedidaMetrics),
                          const SizedBox(height: AppSizes.p16),
                          TrendChart(monthlyTrends: data.monthlyTrends, yearlyTrends: data.yearlyTrends),
                          const SizedBox(height: AppSizes.p16),
                          BreakdownListCard(title: AppStrings.appointmentsByStatus, data: data.statusBreakdown, barColor: AppColors.success),
                          const SizedBox(height: AppSizes.p16),
                          BreakdownListCard(title: AppStrings.appointmentsByType, data: data.typeBreakdown, barColor: AppColors.info),
                          const SizedBox(height: AppSizes.p16),
                          BreakdownListCard(title: AppStrings.appointmentsPerDoctor, data: data.doctorBreakdown, barColor: AppColors.primary),
                        ],
                      );
                    },
                    loading: () => ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSizes.p16),
                      children: [
                        GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppSizes.p12,
                          mainAxisSpacing: AppSizes.p12,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: const [
                            StatsMetricCard(title: '', value: '', icon: Icons.people, isLoading: true),
                            StatsMetricCard(title: '', value: '', icon: Icons.person_add, isLoading: true),
                            StatsMetricCard(title: '', value: '', icon: Icons.calendar_today, isLoading: true),
                            StatsMetricCard(title: '', value: '', icon: Icons.medical_services, isLoading: true),
                          ],
                        ),
                        const SizedBox(height: AppSizes.p16),
                        RevenueSummaryCard(grossIncome: 0, totalPackageBalances: 0, isLoading: true),
                        const SizedBox(height: AppSizes.p16),
                        BranchComparisonCard(tagamoa: const BranchMetrics(totalPatients: 0, totalAppointments: 0, grossIncome: 0), masrElgedida: const BranchMetrics(totalPatients: 0, totalAppointments: 0, grossIncome: 0), isLoading: true),
                      ],
                    ),
                    error: (error, _) => ErrorView(
                      exception: error is AppException ? error : AppException.fromSupabaseException(error),
                      onRetry: () => ref.refresh(reportsDataProvider.future),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
