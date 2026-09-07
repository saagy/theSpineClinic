import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

/// Labeled pane container for the wide split-view booking workboard.
class BookingWorkboardPane extends StatelessWidget {
  const BookingWorkboardPane({
    super.key,
    required this.title,
    required this.count,
    required this.child,
  });

  final String title;
  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.sectionCount(title, count),
          style: AppTextStyles.headingSmall,
        ),
        const SizedBox(height: AppSizes.p12),
        Expanded(child: child),
      ],
    );
  }
}

/// Loading skeleton for the mobile segmented tabs.
class BookingWorkboardTabsSkeleton extends StatelessWidget {
  const BookingWorkboardTabsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p12,
        vertical: AppSizes.p8,
      ),
      child: Row(
        children: const [
          Expanded(child: SkeletonBox(height: 44, borderRadius: 999)),
          SizedBox(width: AppSizes.p8),
          Expanded(child: SkeletonBox(height: 44, borderRadius: 999)),
        ],
      ),
    );
  }
}
