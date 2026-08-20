import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/shared/widgets/animated_metric_counter.dart';
import 'package:spine_clinic_app/shared/widgets/pressable_scale.dart';
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
    this.onTap,
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

  /// Optional tap callback for metric drill-downs.
  final VoidCallback? onTap;

  Widget _buildValue(BuildContext context) {
    final String clean = value.replaceAll(RegExp(r'[^0-9.]'), '');
    final num? parsed = num.tryParse(clean);
    if (parsed != null && value.length <= 10 && !value.contains(':')) {
      final String prefix = value.startsWith('\$') ? '\$' : '';
      final String suffix = value.endsWith('%') ? '%' : '';
      return AnimatedMetricCounter(
        value: parsed,
        prefix: prefix,
        suffix: suffix,
        style: AppTextStyles.numberLarge.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      );
    }
    return Text(
      value,
      style: AppTextStyles.numberLarge.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

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
                  height: AppSizes.skeletonLabelHeight,
                  width: AppSizes.skeletonLabelWidth,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline,
                    borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r4)),
                  ),
                ),
                if (icon != null)
                  Container(
                    height: AppSizes.iconDefault,
                    width: AppSizes.iconDefault,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outline,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.p12),
            Container(
              height: AppSizes.skeletonValueHeight,
              width: AppSizes.skeletonValueWidth,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r4)),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSizes.p8),
              Container(
                height: AppSizes.skeletonSubtitleHeight,
                width: AppSizes.skeletonSubtitleWidth,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r4)),
                ),
              ),
            ],
          ],
        ),
      );
    }

    final Widget card = SectionCard(
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: AppSizes.p8),
                Icon(
                  icon,
                  color: ClinicColors.of(context).textMuted,
                  size: AppSizes.iconDefault,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSizes.p8),
          _buildValue(context),
          if (subtitle != null) ...[
            const SizedBox(height: AppSizes.p4),
            Text(
              subtitle!,
              style: AppTextStyles.caption.copyWith(
                color: ClinicColors.of(context).textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return PressableScale(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}
