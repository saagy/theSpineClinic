import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';

/// Renders a list of metrics as a breakdown of progress bars.
class BreakdownListCard extends StatelessWidget {
  /// Creates a [BreakdownListCard] instance.
  const BreakdownListCard({
    super.key,
    required this.title,
    required this.data,
    this.barColor = AppColors.primary,
  });

  /// The title of this breakdown card.
  final String title;

  /// The map of key-value pairs representing metrics counts.
  final Map<String, int> data;

  /// The theme color of progress indicators.
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    final int total = data.values.fold(0, (sum, val) => sum + val);

    return SectionCard(
      title: title,
      child: total == 0
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.p24),
              child: Center(
                child: Text(
                  AppStrings.noRecordsInWindow,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: data.entries.map((entry) {
                final String label = entry.key;
                final int count = entry.value;
                final double percent = total > 0 ? count / total : 0.0;

                // Format status database values to human readable if needed
                final displayLabel = label.replaceAll('_', ' ').toUpperCase();

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.p12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              displayLabel,
                              style: AppTextStyles.captionBold.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSizes.p8),
                          Text(
                            '$count (${(percent * 100).toStringAsFixed(0)}%)',
                            style: AppTextStyles.number.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.p4),
                      ClipRRect(
                        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r4)),
                        child: LinearProgressIndicator(
                          value: percent,
                          backgroundColor: AppColors.background,
                          valueColor: AlwaysStoppedAnimation<Color>(barColor),
                          minHeight: AppSizes.p6,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}
