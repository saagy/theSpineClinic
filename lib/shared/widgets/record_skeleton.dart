import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

class RecordSkeleton extends StatelessWidget {
  const RecordSkeleton({super.key, this.rows = 2});
  final int rows;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < rows; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FractionallySizedBox(widthFactor: 0.65, child: SkeletonBox(height: AppSizes.p20)),
                const SizedBox(height: AppSizes.p12),
                const FractionallySizedBox(widthFactor: 0.85, child: SkeletonBox(height: AppSizes.p12)),
                const SizedBox(height: AppSizes.p8),
                const FractionallySizedBox(widthFactor: 0.4, child: SkeletonBox(height: AppSizes.p12)),
              ],
            ),
          ),
      ],
    ),
  );
}

class RecordTransition extends StatelessWidget {
  const RecordTransition({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 200);
    return AnimatedSize(
      duration: duration,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: duration,
        child: SizedBox(key: ValueKey(child.runtimeType), width: double.infinity, child: child),
      ),
    );
  }
}
