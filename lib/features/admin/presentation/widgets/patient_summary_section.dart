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

/// Section displaying patient KPIs: registrations, active count, branch
/// distribution, and returning-vs-new ratio. Loads independently.
class PatientSummarySection extends ConsumerWidget {
  const PatientSummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(patientSummaryProvider);

    return asyncData.when(
      loading: () => _buildLoading(),
      error: (error, _) => ErrorView(
        exception: error is AppException ? error : AppException.fromSupabaseException(error),
        onRetry: () => ref.invalidate(patientSummaryProvider),
      ),
      data: (data) => _buildData(data),
    );
  }

  Widget _buildLoading() {
    return Column(
      children: [
        Row(
          children: const [
            Expanded(child: StatsMetricCard(title: '', value: '', icon: Icons.person_add_rounded, isLoading: true)),
            SizedBox(width: AppSizes.p12),
            Expanded(child: StatsMetricCard(title: '', value: '', icon: Icons.people_alt_rounded, isLoading: true)),
          ],
        ),
        const SizedBox(height: AppSizes.p12),
        Row(
          children: const [
            Expanded(child: StatsMetricCard(title: '', value: '', icon: Icons.replay_rounded, isLoading: true)),
            SizedBox(width: AppSizes.p12),
            Expanded(child: StatsMetricCard(title: '', value: '', icon: Icons.account_tree_rounded, isLoading: true)),
          ],
        ),
      ],
    );
  }

  Widget _buildData(PatientSummary data) {
    final bool isEmpty = data.totalActivePatients == 0;

    if (isEmpty) {
      return const EmptyState(message: AppStrings.noPatientData, icon: Icons.people_alt_rounded);
    }

    final String returningPercent = '${(data.returningRatio * 100).toStringAsFixed(0)}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: StatsMetricCard(title: AppStrings.newRegistrations, value: '${data.newRegistrations}', subtitle: AppStrings.registeredInPeriod, icon: Icons.person_add_rounded)),
            const SizedBox(width: AppSizes.p12),
            Expanded(child: StatsMetricCard(title: AppStrings.activePatients, value: '${data.totalActivePatients}', icon: Icons.people_alt_rounded)),
          ],
        ),
        const SizedBox(height: AppSizes.p12),
        Row(
          children: [
            Expanded(child: StatsMetricCard(title: AppStrings.returningVsNew, value: returningPercent, subtitle: AppStrings.returningVsNew, icon: Icons.replay_rounded)),
            const SizedBox(width: AppSizes.p12),
            Expanded(child: StatsMetricCard(title: AppStrings.branchComparison, value: '${data.patientsByBranch.length}', subtitle: AppStrings.patientsByBranch, icon: Icons.account_tree_rounded)),
          ],
        ),
        const SizedBox(height: AppSizes.p16),
        BreakdownListCard(title: AppStrings.patientsByBranch, data: data.patientsByBranch, barColor: AppColors.primary),
      ],
    );
  }
}
