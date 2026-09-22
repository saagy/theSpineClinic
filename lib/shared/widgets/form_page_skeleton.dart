import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

/// Placeholder for a form whose record or permissions have not loaded yet.
class FormPageSkeleton extends StatelessWidget {
  const FormPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSizes.formLayoutMaxWidth,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SkeletonBox(
                  width: AppSizes.recordFactWidth,
                  height: AppSizes.p24,
                ),
                const SizedBox(height: AppSizes.p24),
                for (int i = 0; i < 4; i++) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: SkeletonBox(
                      width: AppSizes.skeletonLabelWidth,
                      height: AppSizes.skeletonLabelHeight,
                    ),
                  ),
                  const SizedBox(height: AppSizes.p8),
                  const SkeletonBox(
                    height: AppSizes.inputHeight,
                    borderRadius: AppSizes.r8,
                  ),
                  const SizedBox(height: AppSizes.p20),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
