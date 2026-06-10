import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';

/// Displays gross income and total package balances summary.
class RevenueSummaryCard extends StatelessWidget {
  const RevenueSummaryCard({
    super.key,
    required this.grossIncome,
    required this.totalPackageBalances,
    this.isLoading = false,
  });

  final double grossIncome;
  final int totalPackageBalances;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildSkeleton();
    }

    return SectionCard(
      child: Row(
        children: [
          Expanded(child: _MetricTile(
            label: AppStrings.grossIncome,
            value: '$grossIncome',
            icon: Icons.trending_up_rounded,
            color: AppColors.success,
          )),
          Container(
            width: AppSizes.borderWidth,
            height: AppSizes.revenueIconSize + AppSizes.p16,
            color: AppColors.border,
          ),
          Expanded(child: _MetricTile(
            label: AppStrings.totalPackageBalances,
            value: '$totalPackageBalances ${AppStrings.activeSessions}',
            icon: Icons.inventory_2_rounded,
            color: AppColors.info,
          )),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return SectionCard(
      child: Row(
        children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _skeletonBox(AppSizes.skeletonLabelWidth, AppSizes.skeletonLabelHeight),
              const SizedBox(height: AppSizes.p8),
              _skeletonBox(AppSizes.skeletonValueWidth, AppSizes.skeletonValueHeight),
            ],
          )),
          const SizedBox(width: AppSizes.p16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _skeletonBox(AppSizes.skeletonLabelWidth, AppSizes.skeletonLabelHeight),
              const SizedBox(height: AppSizes.p8),
              _skeletonBox(AppSizes.skeletonValueWidth, AppSizes.skeletonValueHeight),
            ],
          )),
        ],
      ),
    );
  }

  Widget _skeletonBox(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.r4)),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: AppSizes.revenueIconSize,
              height: AppSizes.revenueIconSize,
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r8)),
              ),
              child: Icon(icon, color: color, size: AppSizes.iconDefault),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.p12),
        Text(label, style: AppTextStyles.captionMedium.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSizes.p4),
        Text(value, style: AppTextStyles.numberLarge.copyWith(color: AppColors.textPrimary)),
      ],
    );
  }
}
