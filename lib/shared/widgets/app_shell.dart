/// Master scaffold shell — adaptive navigation.
///
/// Narrow (<600 px): M3 [NavigationBar] at the bottom.
/// Wide (>=600 px): M3 [NavigationRail] on the left, content fills the rest.
///
/// Rule 1 — under 200 lines. Rule 15/16 — theme-driven colors.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/shared/widgets/app_nav_bar.dart';
import 'package:spine_clinic_app/shared/widgets/app_nav_rail.dart';
import 'package:spine_clinic_app/shared/widgets/loading_overlay.dart';

/// Root application shell with adaptive navigation.
///
/// When [showBrandedAppBar] is false, the shell renders only the navigation
/// — sub-page screens provide their own [Scaffold] + [AppBar].
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
  final bool showBrandedAppBar;

  static const double _wideBreakpoint = 600;

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: isGlobalLoading,
      child: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth >= _wideBreakpoint
            ? _buildWide(context)
            : _buildNarrow(context),
      ),
    );
  }

  Widget _buildWide(BuildContext context) {
    return Scaffold(
      body: Row(children: [
        AppNavRail(
          currentIndex: currentTabIndex,
          onTabSelected: onTabSelected,
          userRole: userRole,
        ),
        Expanded(
          child: Scaffold(
            appBar: showBrandedAppBar
                ? _BrandedAppBar(userRole: userRole, actions: actions)
                : null,
            body: child,
          ),
        ),
      ]),
    );
  }

  Widget _buildNarrow(BuildContext context) {
    return Scaffold(
      appBar: showBrandedAppBar
          ? _BrandedAppBar(userRole: userRole, actions: actions)
          : null,
      body: child,
      bottomNavigationBar: AppNavBar(
        currentIndex: currentTabIndex,
        onTabSelected: onTabSelected,
        userRole: userRole,
      ),
    );
  }
}

class _BrandedAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _BrandedAppBar({required this.userRole, this.actions});
  final String userRole;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(AppSizes.appBarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      height: AppSizes.appBarHeight,
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
          child: Row(children: [
            Container(
              width: AppSizes.iconDefault + AppSizes.p4,
              height: AppSizes.iconDefault + AppSizes.p4,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(AppSizes.r8),
              ),
              child: Icon(Icons.spa_rounded,
                  color: cs.onPrimary, size: AppSizes.iconDefault),
            ),
            const SizedBox(width: AppSizes.p12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.appName, style: AppTextStyles.brand),
                Text(AppStrings.appTagline,
                    style: AppTextStyles.caption
                        .copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
            const Spacer(),
            _HomeButton(userRole: userRole),
            if (actions != null && actions!.isNotEmpty) ...actions!,
          ]),
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
      icon: Icon(Icons.home_rounded,
          color: Theme.of(context).colorScheme.primary),
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
