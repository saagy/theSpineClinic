import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';

/// Standalone analytics metric card featuring high-density design.
/// Includes support for grey skeleton loaders during background data fetching.
class StatsMetricCard extends StatelessWidget {
  /// Creates a [StatsMetricCard] instance.
  const StatsMetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.isLoading = false,
  });

  /// The descriptor label of this metric.
  final String title;

  /// The numerical or textual value of this metric.
  final String value;

  /// Optional contextual subtext below the value.
  final String? subtitle;

  /// Optional visual icon aligned on the right.
  final IconData? icon;

  /// Whether to render the card inside a loading skeleton state.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: 14,
                  width: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.all(Radius.circular(AppSizes.r4)),
                  ),
                ),
                if (icon != null)
                  Container(
                    height: AppSizes.iconDefault,
                    width: AppSizes.iconDefault,
                    decoration: const BoxDecoration(
                      color: AppColors.border,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.p12),
            Container(
              height: 24,
              width: 50,
              decoration: const BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.all(Radius.circular(AppSizes.r4)),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSizes.p8),
              Container(
                height: 12,
                width: 110,
                decoration: const BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.all(Radius.circular(AppSizes.r4)),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.captionMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: AppSizes.p8),
                Icon(
                  icon,
                  color: AppColors.textMuted,
                  size: AppSizes.iconDefault,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSizes.p8),
          Text(
            value,
            style: AppTextStyles.numberLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSizes.p4),
            Text(
              subtitle!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
