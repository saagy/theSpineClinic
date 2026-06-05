library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';

/// A stateless widget that previews the generated appointment slots.
class BookingSlotsPreview extends StatelessWidget {
  /// Creates a [BookingSlotsPreview].
  const BookingSlotsPreview({
    super.key,
    required this.slots,
    required this.timeOfDay,
  });

  /// List of generated date slots.
  final List<DateTime> slots;

  /// Selected time of day for preview.
  final TimeOfDay? timeOfDay;

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scheduled Slots Preview (${slots.length})',
          style: AppTextStyles.bodyBold.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.p8),
        Wrap(
          spacing: AppSizes.p8,
          runSpacing: AppSizes.p8,
          children: slots.map((date) {
            final String dateStr = Formatters.formatDateShort(date);
            final String timeStr = timeOfDay != null
                ? Formatters.formatTime(DateTime(2026, 1, 1, timeOfDay!.hour, timeOfDay!.minute))
                : '';
            final String label = timeStr.isNotEmpty ? '$dateStr at $timeStr' : dateStr;

            return Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(13),
                borderRadius: const BorderRadius.all(Radius.circular(AppSizes.p8)),
                border: Border.all(
                  color: AppColors.primary.withAlpha(51),
                  width: AppSizes.borderWidth,
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.p12,
                vertical: AppSizes.p6,
              ),
              child: Text(
                label,
                style: AppTextStyles.captionMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
