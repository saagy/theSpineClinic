import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

/// High-density skeleton loader for the patients table/list.
class PatientTableSkeleton extends StatelessWidget {
  const PatientTableSkeleton({super.key, this.isDesktop = true});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 10,
      separatorBuilder: (_, __) => Divider(
        height: AppSizes.borderWidth,
        thickness: AppSizes.borderWidth,
        color: cs.outlineVariant.withAlpha(80),
      ),
      itemBuilder: (_, __) => isDesktop ? _buildDesktopRow() : _buildMobileRow(),
    );
  }

  Widget _buildDesktopRow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p12),
      child: Row(
        children: [
          SkeletonCircle(radius: 16),
          SizedBox(width: AppSizes.p12),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 140, height: 14),
                SizedBox(height: AppSizes.p4),
                SkeletonBox(width: 90, height: 11),
              ],
            ),
          ),
          Expanded(flex: 2, child: SkeletonBox(width: 70, height: 20)),
          Expanded(flex: 3, child: SkeletonBox(width: 110, height: 14)),
          Expanded(flex: 2, child: SkeletonBox(width: 80, height: 22)),
          Expanded(flex: 2, child: SkeletonBox(width: 85, height: 14)),
          SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildMobileRow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonCircle(radius: 18),
          SizedBox(width: AppSizes.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 160, height: 15),
                SizedBox(height: AppSizes.p6),
                SkeletonBox(width: 100, height: 12),
                SizedBox(height: AppSizes.p8),
                Row(
                  children: [
                    SkeletonBox(width: 75, height: 20),
                    SizedBox(width: AppSizes.p8),
                    SkeletonBox(width: 90, height: 16),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
