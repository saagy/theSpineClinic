/// Pill-indicator TabBar — always scrollable with right-edge fade.
///
/// Rule 15/16 — all colours via Theme.of(context).colorScheme.
library;

import 'package:flutter/material.dart';

import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

class PillTabBar extends StatelessWidget {
  const PillTabBar({super.key, required this.tabs});
  final List<Tab> tabs;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Material(
          color: cs.surface,
          child: TabBar(
            labelColor: cs.onPrimary,
            unselectedLabelColor: cs.onSurfaceVariant,
            labelStyle: AppTextStyles.captionBold,
            unselectedLabelStyle: AppTextStyles.captionMedium,
            indicator: BoxDecoration(
              color: cs.primary,
              borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r24)),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.fromLTRB(
                AppSizes.p16, AppSizes.p4, AppSizes.p32, AppSizes.p4),
            tabs: tabs,
          ),
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
                  colors: [cs.surface, cs.surface.withAlpha(0)],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
