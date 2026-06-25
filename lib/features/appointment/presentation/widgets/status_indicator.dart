/// Micro status indicator — compact, borderless text or micro-pill.
///
/// Rule 1 — under 200 lines.
/// Rule 7 — all labels via [AppStrings].
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';

/// Premium micro-indicator: borderless, compact styling per status.
class StatusIndicator extends StatelessWidget {
  const StatusIndicator({super.key, required this.status});
  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      AppointmentStatus.checkedIn => Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.p8, vertical: AppSizes.p2),
          decoration: BoxDecoration(
            color: AppColors.checkedInBg,
            borderRadius:
                const BorderRadius.all(Radius.circular(AppSizes.r24)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check, size: 12, color: AppColors.primaryDeep),
              const SizedBox(width: AppSizes.p2),
              Flexible(
                child: Text(AppStrings.statusCheckedIn,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.captionBold.copyWith(
                      fontSize: 11,
                      color: AppColors.primaryDeep,
                    )),
              ),
            ],
          ),
        ),
      AppointmentStatus.cancelled => Text(AppStrings.statusCancelled,
          style: AppTextStyles.captionBold.copyWith(
            fontSize: 11,
            color: AppColors.error,
          )),
      _ => Text(AppStrings.statusScheduled,
          style: AppTextStyles.captionBold.copyWith(
            fontSize: 11,
            color: AppColors.textMuted,
          )),
    };
  }
}
