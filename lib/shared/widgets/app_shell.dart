/// Master scaffold shell with branded AppBar and floating capsule navigation.
///
/// Uses a Stack so the GNav island floats detached from screen edges over
/// scrolling content. A bottom inset on the child ensures list items clear
/// the floating bar.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_nav.dart';
import 'package:spine_clinic_app/shared/widgets/loading_overlay.dart';

/// Floating nav island total height: ~50 content + 20 padding + 20 margin ≈ 92.
const double _kNavClearance = 96;

/// Root application shell with branded AppBar and floating capsule bottom nav.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.child,
    required this.currentTabIndex,
    required this.onTabSelected,
    required this.userRole,
    this.isGlobalLoading = false,
    this.actions,
  });
  final Widget child;
  final int currentTabIndex;
  final ValueSetter<int> onTabSelected;
  final String userRole;
  final bool isGlobalLoading;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: isGlobalLoading,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            // Content with bottom clearance so lists scroll past the island
            Padding(
              padding: const EdgeInsets.only(bottom: _kNavClearance),
              child: child,
            ),
            // Floating capsule nav
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AppBottomNav(
                currentTabIndex: currentTabIndex,
                onTabSelected: onTabSelected,
                userRole: userRole,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(AppSizes.appBarHeight),
      child: Container(
        height: AppSizes.appBarHeight,
        decoration: const BoxDecoration(color: AppColors.surface),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
            child: Row(children: [
              Container(
                width: AppSizes.iconDefault + 4,
                height: AppSizes.iconDefault + 4,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius:
                      const BorderRadius.all(Radius.circular(AppSizes.r8)),
                ),
                child: const Icon(Icons.spa_rounded,
                    color: AppColors.textOnPrimary,
                    size: AppSizes.iconDefault),
              ),
              const SizedBox(width: AppSizes.p12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.appName, style: AppTextStyles.brand),
                  Text(AppStrings.appTagline,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textMuted)),
                ],
              ),
              const Spacer(),
              if (actions != null && actions!.isNotEmpty)
                Row(mainAxisSize: MainAxisSize.min, children: actions!),
            ]),
          ),
        ),
      ),
    );
  }
}
