import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/shared/widgets/record_skeleton.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

class WorkspacePageSkeleton extends StatelessWidget {
  const WorkspacePageSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: double.infinity),
      child: ListView(
        padding: const EdgeInsets.all(AppSizes.p16),
        children: [
          const Row(
            children: [
              SkeletonBox(height: AppSizes.patientHeaderAvatarSize, width: AppSizes.patientHeaderAvatarSize),
              SizedBox(width: AppSizes.p16),
              Expanded(child: SkeletonBox(height: AppSizes.p32)),
            ],
          ),
          const SizedBox(height: AppSizes.p12),
          const FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: 0.4,
            child: SkeletonBox(height: AppSizes.p16),
          ),
          const SizedBox(height: AppSizes.p24),
          const SkeletonBox(height: AppSizes.tappableMin),
          const SizedBox(height: AppSizes.p24),
          LayoutBuilder(
            builder: (context, constraints) {
              Widget panel() => const RecordSkeleton(rows: 3);
              if (constraints.maxWidth < AppSizes.patientWorkspaceBreakpoint) return panel();
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: panel()),
                  const SizedBox(width: AppSizes.p24),
                  Expanded(child: panel()),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}
