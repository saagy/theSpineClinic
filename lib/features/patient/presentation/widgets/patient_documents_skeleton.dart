/// Skeleton loading state for the patient documents tab.
///
/// Matches the 2-column grid visual layout of [PatientTabDocuments]:
/// - Responsive grid matching [PatientDocumentItem] aspect ratio and spacing
/// - Document preview thumbnail area with icon and action button placeholders
/// - File title and upload date placeholders
///
/// Rule 1 — under 200 lines.
/// Rule 15/16 — colors via Theme.of(context).colorScheme.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

/// Skeleton placeholder for the patient documents tab grid view.
class PatientDocumentsSkeleton extends StatelessWidget {
  const PatientDocumentsSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth < 600
        ? 2
        : (screenWidth / 300).floor().clamp(2, 6);

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p16,
        0,
        AppSizes.p16,
        AppSizes.p16,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppSizes.p12,
        mainAxisSpacing: AppSizes.p12,
        childAspectRatio: 0.72,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => _buildDocumentCard(colors),
    );
  }

  Widget _buildDocumentCard(ColorScheme colors) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AppSizes.borderRadiusCard,
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              color: colors.surfaceContainerHighest.withAlpha(40),
              child: Stack(
                children: const [
                  Center(
                    child: SkeletonBox(
                      width: 36,
                      height: 36,
                      borderRadius: AppSizes.r8,
                    ),
                  ),
                  Positioned(
                    top: AppSizes.p8,
                    right: AppSizes.p8,
                    child: SkeletonCircle(radius: 12),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                SkeletonBox(width: double.infinity, height: 13),
                SizedBox(height: AppSizes.p6),
                SkeletonBox(width: 70, height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
