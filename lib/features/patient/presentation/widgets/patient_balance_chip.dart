/// Compact pill badge showing a patient's two package balances at a glance.
///
/// Two stacked tonal dots — teal for PT, amber for traction — each tinted
/// green when positive and rose when <= 0. Rule 13 — no dividers,
/// 4 px internal padding, 6 px corner radius for the pill body.
///
/// Rule 8 — colours come from the central palette and never peek
/// into widget styles directly when used in screens.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// A two-segment pill badge showing PT + traction balances side-by-side.
class PatientBalanceChip extends StatelessWidget {
  /// Creates a [PatientBalanceChip].
  const PatientBalanceChip({
    super.key,
    required this.sessionBalance,
    required this.tractionBalance,
  });

  /// Number of PT sessions credited/debited to the patient.
  final int sessionBalance;

  /// Number of traction sessions credited/debited to the patient.
  final int tractionBalance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p8,
        vertical: AppSizes.p4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: AppSizes.borderWidth),
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Segment(label: 'PT', value: sessionBalance, accent: AppColors.primary),
          const SizedBox(width: AppSizes.p8),
          Container(width: 1, height: AppSizes.p12, color: AppColors.border),
          const SizedBox(width: AppSizes.p8),
          _Segment(label: 'Tr', value: tractionBalance, accent: AppColors.warning),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.value, required this.accent});
  final String label;
  final int value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final bool isWarning = value <= 0;
    final Color fg = isWarning ? AppColors.error : accent;
    final Color bg = isWarning ? AppColors.errorBg : accent.withAlpha(20);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p6,
        vertical: AppSizes.p2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r4)),
      ),
      child: Text(
        '$label $value',
        style: AppTextStyles.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
