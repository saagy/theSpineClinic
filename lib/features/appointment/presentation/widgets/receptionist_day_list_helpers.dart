/// Helper widgets for [ReceptionistDayList]: date header and now indicator.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// Slim header showing total appointment count for the selected day and cancelled toggle.
class ScheduleDateHeader extends StatelessWidget {
  const ScheduleDateHeader({
    super.key,
    required this.count,
    required this.showCancelled,
    required this.onToggleCancelled,
  });

  final int count;
  final bool showCancelled;
  final VoidCallback? onToggleCancelled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final countText = AppStrings.appointmentCountSummary(count);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p20,
        AppSizes.p12,
        AppSizes.p20,
        AppSizes.p4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            countText,
            style: AppTextStyles.captionBold.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (onToggleCancelled != null) ...[
            const SizedBox(width: AppSizes.p8),
            IconButton(
              onPressed: onToggleCancelled,
              tooltip: showCancelled
                  ? AppStrings.hideCancelled
                  : AppStrings.showCancelled,
              color: showCancelled
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              icon: Icon(
                showCancelled
                    ? Icons.event_busy_rounded
                    : Icons.event_busy_outlined,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

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
