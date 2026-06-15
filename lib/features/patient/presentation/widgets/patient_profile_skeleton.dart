/// Profile skeleton shown while patient data loads on the detail screen.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';

import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

class PatientProfileSkeleton extends StatelessWidget {
  const PatientProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // AppBar skeleton
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.p16, AppSizes.p12, AppSizes.p16, AppSizes.p8),
            child: Row(
              children: const [
                SkeletonCircle(radius: 20),
                Spacer(),
                SkeletonCircle(radius: 20),
              ],
            ),
          ),
          // Profile header skeleton
          Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Column(
              children: [
                const SkeletonCircle(radius: 36),
                const SizedBox(height: AppSizes.p12),
                const SkeletonBox(width: 180, height: 18),
                const SizedBox(height: AppSizes.p6),
                const SkeletonBox(width: 120, height: 13),
                const SizedBox(height: AppSizes.p16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    SkeletonBox(width: 80, height: 13),
                    SizedBox(width: AppSizes.p24),
                    SkeletonBox(width: 80, height: 13),
                  ],
                ),
              ],
            ),
          ),
          // Tab bar skeleton
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.p16, vertical: AppSizes.p8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                SkeletonBox(width: 60, height: 32, borderRadius: 999),
                SkeletonBox(width: 100, height: 32, borderRadius: 999),
                SkeletonBox(width: 70, height: 32, borderRadius: 999),
                SkeletonBox(width: 90, height: 32, borderRadius: 999),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.p16),
          // Card skeleton tiles
          const Expanded(child: SkeletonTileList(count: 5)),
        ],
      ),
    );
  }
}
