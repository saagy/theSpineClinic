/// Modular sub-components for the appointment detail skeleton loader.
///
/// Rule 1 — under 200 lines.
/// Rule 15/16 — colors via Theme.of(context).colorScheme.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

/// Patient header skeleton block.
class AppointmentDetailHeaderSkeleton extends StatelessWidget {
  const AppointmentDetailHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p16,
            vertical: AppSizes.p12,
          ),
          child: Row(
            children: const [
              SkeletonCircle(radius: 20),
              SizedBox(width: AppSizes.p12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 140, height: 16),
                    SizedBox(height: AppSizes.p4),
                    SkeletonBox(width: 180, height: 12),
                  ],
                ),
              ),
              SizedBox(width: AppSizes.p8),
              SkeletonBox(
                width: AppSizes.iconSmall,
                height: AppSizes.iconSmall,
                borderRadius: AppSizes.r4,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
          child: Divider(color: cs.outlineVariant, height: 1.0, thickness: 0.5),
        ),
      ],
    );
  }
}

/// Status ribbon banner skeleton.
class AppointmentDetailBannerSkeleton extends StatelessWidget {
  const AppointmentDetailBannerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p16,
        vertical: AppSizes.p12,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(50),
        border: Border(
          left: BorderSide(color: cs.outlineVariant, width: AppSizes.p4),
        ),
      ),
      child: Row(
        children: const [
          SkeletonBox(width: 20, height: 20, borderRadius: 10),
          SizedBox(width: AppSizes.p12),
          SkeletonBox(width: 200, height: 14),
        ],
      ),
    );
  }
}

/// Schedule info card skeleton (Date, Time, Visit Type, Package Status).
class AppointmentDetailInfoCardSkeleton extends StatelessWidget {
  const AppointmentDetailInfoCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CardWrapper(
      children: [
        Row(
          children: [
            Expanded(child: _Field(labelW: 40, valW: 110, valH: 16)),
            SizedBox(width: AppSizes.p16),
            Expanded(child: _Field(labelW: 40, valW: 80, valH: 16)),
          ],
        ),
        SizedBox(height: AppSizes.p16),
        Row(
          children: [
            Expanded(child: _Field(labelW: 65, valW: 90, valH: 14)),
            SizedBox(width: AppSizes.p16),
            Expanded(child: _Field(labelW: 95, valW: 100, valH: 14)),
          ],
        ),
      ],
    );
  }
}

/// Visit notes card skeleton.
class AppointmentDetailNotesCardSkeleton extends StatelessWidget {
  const AppointmentDetailNotesCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CardWrapper(
      children: [
        SkeletonBox(width: 75, height: 12),
        SizedBox(height: AppSizes.p8),
        SkeletonBox(width: double.infinity, height: 44, borderRadius: AppSizes.r8),
      ],
    );
  }
}

/// Assigned doctors card skeleton.
class AppointmentDetailDoctorsCardSkeleton extends StatelessWidget {
  const AppointmentDetailDoctorsCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CardWrapper(
      children: [
        SkeletonBox(width: 60, height: 12),
        SizedBox(height: AppSizes.p12),
        Row(
          children: [
            SkeletonCircle(radius: 14),
            SizedBox(width: AppSizes.p12),
            SkeletonBox(width: 130, height: 14),
          ],
        ),
      ],
    );
  }
}

class _CardWrapper extends StatelessWidget {
  const _CardWrapper({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p16,
        vertical: AppSizes.p8,
      ),
      child: SkeletonCard(children: children),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.labelW, required this.valW, required this.valH});
  final double labelW;
  final double valW;
  final double valH;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBox(width: labelW, height: 10),
        const SizedBox(height: AppSizes.p6),
        SkeletonBox(width: valW, height: valH),
      ],
    );
  }
}
