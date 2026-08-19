/// Helper widgets for appointment day lists: now indicator.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// Now indicator: red dot + current time + horizontal red line.
class ScheduleNowIndicator extends StatelessWidget {
  const ScheduleNowIndicator({super.key});
  static const double _timeWidth = 65;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;
    final now = DateFormat('h:mm a').format(DateTime.now());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
      child: Row(
        children: [
          const SizedBox(width: AppSizes.p16),
          SizedBox(
            width: _timeWidth,
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: errorColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSizes.p4),
                Flexible(
                  child: Text(
                    now,
                    style: AppTextStyles.captionBold.copyWith(
                      color: errorColor,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.p12),
          Expanded(child: Divider(color: errorColor, thickness: 1, height: 0)),
        ],
      ),
    );
  }
}
