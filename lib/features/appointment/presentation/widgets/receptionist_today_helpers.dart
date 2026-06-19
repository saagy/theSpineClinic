/// Helper widgets for [ReceptionistTodayTab]: stats strip, search field,
/// and section header.
///
/// Extracted to keep the parent file under 200 lines.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_providers.dart';

/// Stats strip: Scheduled | Checked In | Cancelled.
class TodayStatsStrip extends StatelessWidget {
  const TodayStatsStrip({super.key, required this.state});
  final ReceptionistAppointmentsState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p20, vertical: AppSizes.p12),
      child: Row(
        children: [
          _Stat(label: 'Scheduled', count: state.scheduledCount,
              color: AppColors.textSecondary),
          const SizedBox(
            height: AppSizes.iconDefault,
            child: VerticalDivider(width: AppSizes.p24, color: AppColors.border),
          ),
          _Stat(label: 'Checked In', count: state.checkedInCount,
              color: AppColors.success),
          const SizedBox(
            height: AppSizes.iconDefault,
            child: VerticalDivider(width: AppSizes.p24, color: AppColors.border),
          ),
          _Stat(label: 'Cancelled', count: state.cancelledCount,
              color: AppColors.error),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.count, required this.color});
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(count.toString(),
              style: AppTextStyles.headingMedium.copyWith(color: color)),
          const SizedBox(height: AppSizes.p2),
          Text(label,
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

/// Search field for the today tab.
class TodaySearchField extends StatelessWidget {
  const TodaySearchField({super.key, required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.p16, AppSizes.p4, AppSizes.p16, AppSizes.p8),
      child: TextField(
        onChanged: onChanged,
        style: AppTextStyles.body,
        decoration: InputDecoration(
          hintText: 'Search by patient name…',
          hintStyle: AppTextStyles.bodySecondary,
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.primary, size: AppSizes.iconDefault),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.p12, vertical: AppSizes.p8),
        ),
      ),
    );
  }
}

/// Section header for grouped appointment lists.
class TodaySectionHeader extends StatelessWidget {
  const TodaySectionHeader({super.key, required this.title, required this.count});
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.p20, AppSizes.p16, AppSizes.p20, AppSizes.p8),
      child: Text(
        '$title · $count',
        style: AppTextStyles.captionBold
            .copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
