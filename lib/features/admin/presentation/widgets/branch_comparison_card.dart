import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/admin/data/admin_repository.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';

/// Side-by-side comparison of Tagamoa vs Masr El-Gedida branch metrics.
class BranchComparisonCard extends StatelessWidget {
  const BranchComparisonCard({
    super.key,
    required this.tagamoa,
    required this.masrElgedida,
    this.isLoading = false,
  });

  final BranchMetrics tagamoa;
  final BranchMetrics masrElgedida;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildSkeleton();

    return SectionCard(
      title: AppStrings.branchComparison,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _BranchColumn(
            name: AppStrings.clinicTagamoa,
            metrics: tagamoa,
          )),
          Container(
            width: AppSizes.borderWidth,
            height: AppSizes.p48 * 3,
            color: AppColors.border,
            margin: const EdgeInsets.symmetric(horizontal: AppSizes.p12),
          ),
          Expanded(child: _BranchColumn(
            name: AppStrings.clinicMasrElgedida,
            metrics: masrElgedida,
          )),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return SectionCard(
      title: AppStrings.branchComparison,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _skeletonColumn()),
          Container(
            width: AppSizes.borderWidth,
            height: AppSizes.p48 * 3,
            color: AppColors.border,
            margin: const EdgeInsets.symmetric(horizontal: AppSizes.p12),
          ),
          Expanded(child: _skeletonColumn()),
        ],
      ),
    );
  }

  Widget _skeletonColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(3, (_) => Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.p12),
        child: Container(
          height: AppSizes.skeletonLabelHeight,
          width: AppSizes.skeletonLabelWidth,
          decoration: const BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.all(Radius.circular(AppSizes.r4)),
          ),
        ),
      )),
    );
  }
}

class _BranchColumn extends StatelessWidget {
  const _BranchColumn({required this.name, required this.metrics});
  final String name;
  final BranchMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: AppTextStyles.bodyBold.copyWith(color: AppColors.primary)),
        const SizedBox(height: AppSizes.p12),
        _row(AppStrings.patients, '${metrics.totalPatients}'),
        const SizedBox(height: AppSizes.p8),
        _row(AppStrings.appointments, '${metrics.totalAppointments}'),
        const SizedBox(height: AppSizes.p8),
        _row(AppStrings.revenue, '$metrics.grossIncome'),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        Text(value, style: AppTextStyles.bodyBold.copyWith(color: AppColors.textPrimary)),
      ],
    );
  }
}
