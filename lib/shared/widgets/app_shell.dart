/// Master scaffold shell that wraps all feature screens.
///
/// Controls the top AppBar, bottom role-driven navigation bar, and
/// intercepts background system events via a global loading overlay.
///
/// Rule 1 — keep files under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_nav.dart';
import 'package:spine_clinic_app/shared/widgets/loading_overlay.dart';

/// The root application shell providing a consistent AppBar, bottom
/// navigation, and global loading state across every feature screen.
class AppShell extends StatelessWidget {
  /// Creates an [AppShell].
  const AppShell({
    super.key,
    required this.child,
    required this.currentTabIndex,
    required this.onTabSelected,
    required this.userRole,
    required this.title,
    this.isGlobalLoading = false,
    this.actions,
  });

  /// The active inner screen content pushed by the router.
  final Widget child;

  /// Tracking active bottom navigation highlighting coordinates.
  final int currentTabIndex;

  /// Navigation routing bridge callback passed down to the sub-nav bar.
  final ValueSetter<int> onTabSelected;

  /// The logged-in staff role (super_admin, receptionist, doctor).
  final String userRole;

  /// Text string displayed in the app header.
  final String title;

  /// When true, activates a root blocking loader over the entire shell.
  final bool isGlobalLoading;

  /// Optional trailing header action icons (e.g., profile, logout).
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    // LoadingOverlay wraps the ENTIRE scaffold so that when active,
    // it blocks interaction with the AppBar, body, AND BottomNav.
    return LoadingOverlay(
      isLoading: isGlobalLoading,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: child,
        bottomNavigationBar: AppBottomNav(
          currentTabIndex: currentTabIndex,
          onTabSelected: onTabSelected,
          userRole: userRole,
        ),
      ),
    );
  }

  /// Constructs a flat, borderless, Stripe-styled AppBar.
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(AppSizes.appBarHeight),
      child: Container(
        height: AppSizes.appBarHeight,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            bottom: BorderSide(
              color: AppColors.border,
              width: AppSizes.borderWidth,
            ),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
            child: Row(
              children: [
                // Title pinned left
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.headingSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Trailing action icons
                if (actions != null && actions!.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
