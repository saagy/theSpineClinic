/// Skeleton loading state for the patient payments tab.
///
/// Matches the visual hierarchy of [PatientTabPayments]:
/// - Wallet balance summary header card (Total Paid / Total Outstanding)
/// - Record Payment pill button
/// - Payment History title
/// - Payment row cards with reason, amount, metadata, status badge, and ledger box
///
/// Rule 1 — under 200 lines.
/// Rule 15/16 — colors via Theme.of(context).colorScheme.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

/// Skeleton placeholder for the patient payments sub-tab.
class PatientPaymentsSkeleton extends StatelessWidget {
  const PatientPaymentsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSizes.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Summary Header Card
          Container(
            padding: const EdgeInsets.all(AppSizes.p20),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withAlpha(40),
              borderRadius: BorderRadius.circular(AppSizes.r16),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: const [
                      SkeletonBox(width: 65, height: 11),
                      SizedBox(height: AppSizes.p4),
                      SkeletonBox(width: 95, height: 22, borderRadius: AppSizes.r4),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: AppSizes.p32,
                  color: cs.outlineVariant,
                ),
                Expanded(
                  child: Column(
                    children: const [
                      SkeletonBox(width: 105, height: 11),
                      SizedBox(height: AppSizes.p4),
                      SkeletonBox(width: 95, height: 22, borderRadius: AppSizes.r4),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.p16),

          // 2. Record Payment Action Button
          const SkeletonBox(
            width: double.infinity,
            height: 48,
            borderRadius: 999,
          ),
          const SizedBox(height: AppSizes.p24),

          // 3. Payment History Section Heading
          const Padding(
            padding: EdgeInsets.only(bottom: AppSizes.p12),
            child: SkeletonBox(width: 130, height: 18),
          ),

          // 4. Payment Row Cards
          _buildPaymentCard(cs, hasLedger: true),
          _buildPaymentCard(cs, hasLedger: false),
          _buildPaymentCard(cs, hasLedger: false),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(ColorScheme cs, {required bool hasLedger}) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.p12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        side: BorderSide(color: cs.outlineVariant, width: AppSizes.borderWidth),
      ),
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                SkeletonBox(width: 120, height: 16),
                SkeletonBox(width: 75, height: 18),
              ],
            ),
            const SizedBox(height: AppSizes.p6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                SkeletonBox(width: 150, height: 12),
                SkeletonBox(width: 65, height: 18, borderRadius: AppSizes.r6),
              ],
            ),
            if (hasLedger) ...[
              const SizedBox(height: AppSizes.p12),
              Container(
                padding: const EdgeInsets.all(AppSizes.p12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withAlpha(50),
                  borderRadius: BorderRadius.circular(AppSizes.r8),
                  border: Border.all(
                    color: cs.outlineVariant.withAlpha(120),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    SkeletonBox(width: 100, height: 12),
                    SkeletonBox(width: 60, height: 12),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
