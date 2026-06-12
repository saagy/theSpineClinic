import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/admin/data/analytics_dtos.dart';
import 'package:spine_clinic_app/features/admin/presentation/analytics_providers.dart';
import 'package:spine_clinic_app/features/admin/presentation/widgets/breakdown_list_card.dart';
import 'package:spine_clinic_app/features/admin/presentation/widgets/revenue_summary_card.dart';
import 'package:spine_clinic_app/features/admin/presentation/widgets/stats_metric_card.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

/// Section displaying financial KPIs: revenue, payment types, balances, packages.
/// Loads independently from other analytics sections.
class FinancialSummarySection extends ConsumerWidget {
  const FinancialSummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(financialSummaryProvider);

    return asyncData.when(
      loading: () => _buildLoading(),
      error: (error, _) => ErrorView(
        exception: error is AppException ? error : AppException.fromSupabaseException(error),
        onRetry: () => ref.invalidate(financialSummaryProvider),
      ),
      data: (data) => _buildData(data),
    );
  }

  Widget _buildLoading() {
    return Column(
      children: [
        StatsMetricCard(title: '', value: '', icon: Icons.trending_up_rounded, isLoading: true),
        const SizedBox(height: AppSizes.p16),
        RevenueSummaryCard(grossIncome: 0, totalPackageBalances: 0, isLoading: true),
      ],
    );
  }

  Widget _buildData(FinancialSummary data) {
    final bool isEmpty = data.totalRevenue == 0 && data.packageSalesCount == 0;

    if (isEmpty) {
      return const EmptyState(message: AppStrings.noFinancialData, icon: Icons.account_balance_wallet_rounded);
    }

    final String revenueFormatted = '${AppStrings.egpPrefix}${data.totalRevenue.toStringAsFixed(0)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatsMetricCard(title: AppStrings.totalRevenue, value: revenueFormatted, icon: Icons.trending_up_rounded),
        const SizedBox(height: AppSizes.p16),
        BreakdownListCard(title: AppStrings.revenueByPaymentType, data: _formatPaymentTypes(data.revenueByPaymentType), barColor: AppColors.success),
        const SizedBox(height: AppSizes.p16),
        BreakdownListCard(title: AppStrings.revenueByBranch, data: _formatBranchRevenue(data.revenueByBranch), barColor: AppColors.info),
        const SizedBox(height: AppSizes.p16),
        Row(
          children: [
            Expanded(child: StatsMetricCard(title: AppStrings.outstandingBalances, value: '${data.outstandingBalanceCount}', subtitle: AppStrings.patientsWithNegativeBalance, icon: Icons.warning_amber_rounded)),
            const SizedBox(width: AppSizes.p12),
            Expanded(child: StatsMetricCard(title: AppStrings.packageSales, value: '${data.packageSalesCount}', subtitle: '${AppStrings.egpPrefix}${data.packageSalesValue.toStringAsFixed(0)}', icon: Icons.inventory_2_rounded)),
          ],
        ),
      ],
    );
  }

  Map<String, int> _formatPaymentTypes(Map<String, double> byType) {
    return byType.map((k, v) => MapEntry(_typeLabel(k), v.toInt()));
  }

  String _typeLabel(String key) {
    switch (key) {
      case 'package':
        return AppStrings.packageRedemptions;
      case 'session':
        return AppStrings.session;
      case 'gehaz':
        return AppStrings.gehazShadFakarat;
      default:
        return AppStrings.paymentReasonOther;
    }
  }

  Map<String, int> _formatBranchRevenue(Map<String, double> byBranch) {
    final Map<String, int> result = <String, int>{};
    byBranch.forEach((k, v) {
      final String label = k == 'tagamoa' ? AppStrings.clinicTagamoa : AppStrings.clinicMasrElgedida;
      result[label] = v.toInt();
    });
    return result;
  }
}
