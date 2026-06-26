/// Compact pill badge showing a patient's two package balances.
///
/// Rule 13 — no dividers, uses SizedBox gap instead.
/// Rule 15/16 — all colours via Theme.of(context).colorScheme.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

class PatientBalanceChip extends StatelessWidget {
  const PatientBalanceChip({
    super.key,
    required this.sessionBalance,
    required this.tractionBalance,
  });
  final int sessionBalance;
  final int tractionBalance;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8, vertical: AppSizes.p4),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(AppSizes.r8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Segment(label: 'PT', value: sessionBalance, accent: cs.primary),
          const SizedBox(width: AppSizes.p12),
          _Segment(label: 'Tr', value: tractionBalance, accent: cs.secondary),
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
    final cs = Theme.of(context).colorScheme;
    final bool isWarning = value <= 0;
    final Color fg = isWarning ? cs.error : accent;
    final Color bg = isWarning ? cs.errorContainer : accent.withAlpha(20);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p6, vertical: AppSizes.p2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizes.r4),
      ),
      child: Text(
        '$label $value',
        style: AppTextStyles.caption.copyWith(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}
