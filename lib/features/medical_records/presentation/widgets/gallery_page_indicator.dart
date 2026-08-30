library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';

/// Animated page dot indicator for gallery viewports.
class GalleryPageIndicator extends StatelessWidget {
  const GalleryPageIndicator({
    super.key,
    required this.itemCount,
    required this.currentIndex,
  });

  final int itemCount;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSizes.p12,
        horizontal: AppSizes.p16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(itemCount, (index) {
          final isSelected = index == currentIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: AppSizes.p2),
            width: isSelected ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: isSelected ? cs.primary : cs.outlineVariant,
              borderRadius: BorderRadius.circular(AppSizes.r999),
            ),
          );
        }),
      ),
    );
  }
}
