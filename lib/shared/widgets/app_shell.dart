/// Master scaffold shell — adaptive navigation.
///
/// Narrow (<600 px): M3 [NavigationBar] at the bottom.
/// Wide (>=600 px): M3 [NavigationRail] on the left, content fills the rest.
///
/// Rule 1 — under 200 lines. Rule 15/16 — theme-driven colors.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/shared/widgets/app_nav_bar.dart';
import 'package:spine_clinic_app/shared/widgets/app_nav_rail.dart';
import 'package:spine_clinic_app/shared/widgets/loading_overlay.dart';

/// Root application shell with adaptive navigation.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.child,
    required this.currentTabIndex,
    required this.onTabSelected,
    required this.userRole,
    this.isGlobalLoading = false,
  });
  final Widget child;
  final int currentTabIndex;
  final ValueSetter<int> onTabSelected;
  final String userRole;
  final bool isGlobalLoading;

  static const double _wideBreakpoint = 600;

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: isGlobalLoading,
      child: LayoutBuilder(
        builder: (context, constraints) =>
            constraints.maxWidth >= _wideBreakpoint
            ? _buildWide(context)
            : _buildNarrow(context),
      ),
    );
  }

  Widget _buildContent() => child;

  Widget _buildWide(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AppNavRail(
            currentIndex: currentTabIndex,
            onTabSelected: onTabSelected,
            userRole: userRole,
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildNarrow(BuildContext context) {
    return Scaffold(
      body: _buildContent(),
      bottomNavigationBar: AppNavBar(
        currentIndex: currentTabIndex,
        onTabSelected: onTabSelected,
        userRole: userRole,
      ),
    );
  }
}
