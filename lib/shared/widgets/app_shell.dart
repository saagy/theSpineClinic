/// Master scaffold shell with branded AppBar and floating capsule navigation.
///
/// Uses [Scaffold.bottomNavigationBar] so that modal bottom sheets
/// (e.g. quick-action FAB menus) render above the nav bar instead of
/// being obscured by a Stack-positioned overlay.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_nav.dart';
import 'package:spine_clinic_app/shared/widgets/loading_overlay.dart';

/// Root application shell with branded AppBar and floating capsule bottom nav.
///
/// When [showBrandedAppBar] is false, the shell renders only the bottom
/// navigation — sub-page screens provide their own [Scaffold] + [AppBar].
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.child,
    required this.currentTabIndex,
    required this.onTabSelected,
    required this.userRole,
    this.isGlobalLoading = false,
    this.actions,
    this.showBrandedAppBar = true,
  });
  final Widget child;
  final int currentTabIndex;
  final ValueSetter<int> onTabSelected;
  final String userRole;
  final bool isGlobalLoading;
  final List<Widget>? actions;

  /// Whether to render the branded [AppBar]. Set false for sub-pages that
  /// carry their own titled [AppBar] to avoid stacking two AppBars.
  final bool showBrandedAppBar;

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: isGlobalLoading,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: showBrandedAppBar ? _buildAppBar() : null,
        body: child,
        bottomNavigationBar: AppBottomNav(
          currentTabIndex: currentTabIndex,
          onTabSelected: onTabSelected,
          userRole: userRole,
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
              _HomeButton(userRole: userRole),
              if (actions != null && actions!.isNotEmpty)
                Row(mainAxisSize: MainAxisSize.min, children: actions!),
            ]),
          ),
        ),
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  const _HomeButton({required this.userRole});
  final String userRole;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.home_rounded, color: AppColors.primary),
      tooltip: 'Home',
      onPressed: () => context.go(_homeRoute),
    );
  }

  String get _homeRoute => switch (userRole) {
    'doctor' => AppRoutes.schedule,
    'super_admin' => AppRoutes.schedule,
    _ => AppRoutes.allAppointments,
  };
}
