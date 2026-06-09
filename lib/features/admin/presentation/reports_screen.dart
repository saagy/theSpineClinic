import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/admin/presentation/reports_controller.dart';
import 'package:spine_clinic_app/features/admin/presentation/widgets/breakdown_list_card.dart';
import 'package:spine_clinic_app/features/admin/presentation/widgets/reports_filter_bar.dart';
import 'package:spine_clinic_app/features/admin/presentation/widgets/stats_metric_card.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

/// Screen displaying clinic statistical analytics and performance reports.
/// Protected by a Super Admin role guard.
class ReportsScreen extends ConsumerWidget {
  /// Creates a [ReportsScreen] instance.
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUser = ref.watch(currentUserProvider);

    return asyncUser.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: ErrorView(
          exception: error is AppException
              ? error
              : const UnknownException(message: AppStrings.errorDatabaseQueryFailed),
          onRetry: () => ref.invalidate(currentUserProvider),
        ),
      ),
      data: (user) {
        if (user == null || user.role != UserRole.superAdmin) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: ErrorView(
              exception: UnknownException(
                message: AppStrings.errorDatabasePermissionDenied,
                code: 'security/blocked',
              ),
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
            title: const Text(AppStrings.reports),
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
                      final hasNoData = data.totalPatients == 0 && data.totalAppointments == 0;
                      if (hasNoData) {
                        return const SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 100),
                              child: EmptyState(
                                message: AppStrings.noData,
                                icon: Icons.bar_chart_rounded,
                              ),
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
                              StatsMetricCard(
                                title: 'Total Patients',
                                value: data.totalPatients.toString(),
                                icon: Icons.people_alt_rounded,
                              ),
                              StatsMetricCard(
                                title: 'New Patients',
                                value: data.newPatients.toString(),
                                icon: Icons.person_add_rounded,
                                subtitle: 'Registered in period',
                              ),
                              StatsMetricCard(
                                title: 'Appointments',
                                value: data.totalAppointments.toString(),
                                icon: Icons.calendar_today_rounded,
                                subtitle: 'Booked in period',
                              ),
                              StatsMetricCard(
                                title: 'Active Doctors',
                                value: data.doctorBreakdown.length.toString(),
                                icon: Icons.medical_services_rounded,
                                subtitle: 'Assigned in period',
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.p16),
                          BreakdownListCard(
                            title: 'Appointments by Status',
                            data: data.statusBreakdown,
                            barColor: AppColors.success,
                          ),
                          const SizedBox(height: AppSizes.p16),
                          BreakdownListCard(
                            title: 'Appointments by Type',
                            data: data.typeBreakdown,
                            barColor: AppColors.info,
                          ),
                          const SizedBox(height: AppSizes.p16),
                          BreakdownListCard(
                            title: 'Appointments per Doctor',
                            data: data.doctorBreakdown,
                            barColor: AppColors.primary,
                          ),
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
