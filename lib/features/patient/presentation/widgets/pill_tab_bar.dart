/// Pill-indicator TabBar that centres when all tabs fit, scrolls with a
/// right-edge fade only when they overflow.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

class PillTabBar extends StatelessWidget {
  const PillTabBar({super.key, required this.tabs});
  final List<Tab> tabs;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Estimate total tab width: each tab label ~100px + 32px padding.
          // If the estimate fits the available width, use fixed (centred) tabs.
          const double estimatedTabWidth = 120.0;
          final double totalEstimate = tabs.length * estimatedTabWidth;
          final bool fits = totalEstimate <= constraints.maxWidth;

          if (fits) {
            return TabBar(
              labelColor: AppColors.textOnPrimary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: AppTextStyles.captionBold,
              unselectedLabelStyle: AppTextStyles.captionMedium,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius:
                    const BorderRadius.all(Radius.circular(AppSizes.r24)),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: AppColors.transparent,
              isScrollable: false,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.p16, vertical: AppSizes.p4),
              tabs: tabs,
            );
          }

          return Stack(
            children: [
              TabBar(
                labelColor: AppColors.textOnPrimary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: AppTextStyles.captionBold,
                unselectedLabelStyle: AppTextStyles.captionMedium,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius:
                      const BorderRadius.all(Radius.circular(AppSizes.r24)),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: AppColors.transparent,
                isScrollable: true,
                padding: const EdgeInsets.fromLTRB(
                    AppSizes.p16, AppSizes.p4, AppSizes.p32, AppSizes.p4),
                tabs: tabs,
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Container(
                    width: AppSizes.p24,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [
                          AppColors.surface,
                          AppColors.surface.withAlpha(0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
