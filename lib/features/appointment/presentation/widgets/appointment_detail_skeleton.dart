/// Skeleton loading state for the appointment detail screen.
///
/// Matches the visual hierarchy of [AppointmentDetailBody]:
/// - Patient identity header with avatar
/// - Status ribbon banner
/// - Schedule info card (Date, Time, Visit Type, Package)
/// - Visit notes card
/// - Assigned doctors card
/// - Pinned bottom action button bar
///
/// Rule 1 — under 200 lines.
/// Rule 15/16 — colors via Theme.of(context).colorScheme.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_detail_skeleton_cards.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

/// Skeleton placeholder for the appointment detail screen.
class AppointmentDetailSkeleton extends StatelessWidget {
  const AppointmentDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                AppointmentDetailHeaderSkeleton(),
                AppointmentDetailBannerSkeleton(),
                SizedBox(height: AppSizes.p8),
                AppointmentDetailInfoCardSkeleton(),
                AppointmentDetailNotesCardSkeleton(),
                AppointmentDetailDoctorsCardSkeleton(),
                SizedBox(height: AppSizes.p24),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.p16,
              AppSizes.p12,
              AppSizes.p16,
              AppSizes.p12,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant,
                  width: 0.5,
                ),
              ),
            ),
            child: const SkeletonBox(
              width: double.infinity,
              height: 48,
              borderRadius: 999,
            ),
          ),
        ),
      ],
    );
  }
}
