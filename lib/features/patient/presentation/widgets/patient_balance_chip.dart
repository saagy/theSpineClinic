/// Balance indicator chip for patient list tiles.
///
/// Displays the patient's `packageBalance` as a compact pill-shaped
/// badge. Uses a red warning tint when balance is 0 or negative
/// per Package Rule 7 (AGENT_CONTEXT §7).
///
/// Rule 8 — no hardcoded colours or sizes.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// A compact pill badge showing a patient's package balance count.
class PatientBalanceChip extends StatelessWidget {
  /// Creates a [PatientBalanceChip].
  const PatientBalanceChip({super.key, required this.balance});

  /// The patient's current package balance.
  final int balance;

  @override
  Widget build(BuildContext context) {
    final bool isWarning = balance <= 0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p8,
        vertical: AppSizes.p4,
      ),
      decoration: BoxDecoration(
        color: isWarning ? AppColors.errorBg : AppColors.successBg,
        borderRadius: AppSizes.borderRadiusBadge,
      ),
      child: Text(
        '$balance',
        style: AppTextStyles.caption.copyWith(
          color: isWarning ? AppColors.error : AppColors.success,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
