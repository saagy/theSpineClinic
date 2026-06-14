import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/admin/data/admin_repository.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';

/// Renders a toggle-able trend chart (monthly / yearly) showing
/// visits and revenue as a grouped bar chart.
class TrendChart extends StatefulWidget {
  const TrendChart({
    super.key,
    required this.monthlyTrends,
    required this.yearlyTrends,
    this.isLoading = false,
  });

  final List<TrendPoint> monthlyTrends;
  final List<TrendPoint> yearlyTrends;
  final bool isLoading;

  @override
  State<TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<TrendChart> {
  bool _showMonthly = true;

  @override
  Widget build(BuildContext context) {
    final List<TrendPoint> trends = _showMonthly ? widget.monthlyTrends : widget.yearlyTrends;
    final String title = _showMonthly ? AppStrings.monthlyTrends : AppStrings.yearlyTrends;

    if (widget.isLoading) {
      return SectionCard(
        title: title,
        child: Container(
          height: AppSizes.chartContainerHeight,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return SectionCard(
      title: title,
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleChip(label: AppStrings.thisMonth, selected: _showMonthly, onTap: () => setState(() => _showMonthly = true)),
          const SizedBox(width: AppSizes.p4),
          _ToggleChip(label: AppStrings.yearLabel, selected: !_showMonthly, onTap: () => setState(() => _showMonthly = false)),
        ],
      ),
      child: trends.isEmpty
          ? SizedBox(
              height: AppSizes.chartContainerHeight,
              child: Center(child: Text(AppStrings.noTrendData, style: AppTextStyles.bodySecondary)),
            )
          : SizedBox(
              height: AppSizes.chartContainerHeight,
              child: _ChartBody(trends: trends),
            ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p12, vertical: AppSizes.p4),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r6)),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: AppSizes.borderWidth,
          ),
        ),
        child: Text(label, style: AppTextStyles.captionMedium.copyWith(
          color: selected ? AppColors.primary : AppColors.textSecondary,
        )),
      ),
    );
  }
}

/// Purely token-driven grouped bar chart built with native Flutter layout.
class _ChartBody extends StatelessWidget {
  const _ChartBody({required this.trends});
  final List<TrendPoint> trends;

  @override
  Widget build(BuildContext context) {
    final int maxVisits = trends.fold<int>(0, (m, t) => t.visits > m ? t.visits : m);
    final double maxRevenue = trends.fold<double>(0, (m, t) => t.revenue > m ? t.revenue : m);
    final double maxVal = (maxVisits > maxRevenue ? maxVisits.toDouble() : maxRevenue);

    return Column(
      children: [
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: AppColors.primary, label: AppStrings.visits),
            const SizedBox(width: AppSizes.p16),
            _LegendDot(color: AppColors.success, label: AppStrings.revenue),
          ],
        ),
        const SizedBox(height: AppSizes.p12),
        // Bars
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.p8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: trends.map((t) => _BarGroup(point: t, maxValue: maxVal)).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: AppSizes.p8,
          height: AppSizes.p8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSizes.p4),
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _BarGroup extends StatelessWidget {
  const _BarGroup({required this.point, required this.maxValue});
  final TrendPoint point;
  final double maxValue;

  double _barHeight(int value) {
    if (value <= 0 || maxValue <= 0) return AppSizes.chartBarMinHeight;
    final double ratio = value / maxValue;
    return AppSizes.chartBarMinHeight + ratio * (AppSizes.chartBarMaxHeight - AppSizes.chartBarMinHeight);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Revenue bar (green)
          Container(
            width: AppSizes.chartBarWidth,
            height: _barHeight(point.revenue.toInt()),
            decoration: const BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.r4)),
            ),
          ),
          const SizedBox(height: AppSizes.p2),
          // Visits bar (primary)
          Container(
            width: AppSizes.chartBarWidth,
            height: _barHeight(point.visits),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.r4)),
            ),
          ),
          const SizedBox(height: AppSizes.p4),
          // Label
          SizedBox(
            width: AppSizes.chartBarWidth + AppSizes.p8,
            child: Text(
              point.label,
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, fontSize: AppSizes.fontSizeXs),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
