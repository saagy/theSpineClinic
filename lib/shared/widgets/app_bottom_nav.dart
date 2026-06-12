/// Custom role-driven navigation bar widget matching the Spine Clinic access matrix.
///
/// Dynamically resolves and renders tab options based on the user's role:
/// doctor, receptionist, or super_admin. Touch-only design.
///
/// Rule 1 — keep files under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// Representation of a single navigation tab item.
class _TabItem {
  const _TabItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

/// A role-driven, high-density bottom navigation bar styled with design tokens.
class AppBottomNav extends StatelessWidget {
  /// Creates an [AppBottomNav].
  const AppBottomNav({
    super.key,
    required this.currentTabIndex,
    required this.onTabSelected,
    required this.userRole,
  });

  /// The currently selected tab index.
  final int currentTabIndex;

  /// Callback triggered when a tab is tapped.
  final ValueSetter<int> onTabSelected;

  /// The role string of the logged-in user profile (super_admin, receptionist, doctor).
  final String userRole;

  @override
  Widget build(BuildContext context) {
    // Resolve the navigation tab list dynamically based on userRole
    final List<_TabItem> tabs = _resolveTabsForRole(userRole);

    return Container(
      height: AppSizes.appBarHeight, // Locked to standard 56px height
      decoration: const BoxDecoration(
        color: AppColors.surface, // Pure white background
        border: Border(
          top: BorderSide(
            color: AppColors.border, // Slate 200 thin top divider border
            width: AppSizes.borderWidth,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(tabs.length, (index) {
          final _TabItem tab = tabs[index];
          final bool isSelected = index == currentTabIndex;

          final Color itemColor = isSelected ? AppColors.primary : AppColors.textSecondary;

          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTabSelected(index),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Icon(
                    tab.icon,
                    color: itemColor,
                    size: AppSizes.iconLarge,
                  ),
                  const SizedBox(height: AppSizes.p2), // Ultra-tight spacing grid Nudge
                  Text(
                    tab.label,
                    style: AppTextStyles.captionMedium.copyWith(
                      color: itemColor,
                      fontSize: AppSizes.fontSizeSm2, // Specialized extra-small text layout layer
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  List<_TabItem> _resolveTabsForRole(String role) {
    switch (role) {
      case 'doctor':
        return const [
          _TabItem(icon: Icons.calendar_today_rounded, label: AppStrings.navMySchedule),
          _TabItem(icon: Icons.people_alt_rounded, label: AppStrings.navMyPatients),
          _TabItem(icon: Icons.person_rounded, label: AppStrings.profile),
        ];
      case 'receptionist':
        return const [
          _TabItem(icon: Icons.event_note_rounded, label: AppStrings.navAppts),
          _TabItem(icon: Icons.people_alt_rounded, label: AppStrings.patients),
          _TabItem(icon: Icons.person_rounded, label: AppStrings.profile),
        ];
      case 'super_admin':
      default:
        return const [
          _TabItem(icon: Icons.analytics_rounded, label: AppStrings.navAnalytics),
          _TabItem(icon: Icons.event_note_rounded, label: AppStrings.navAppts),
          _TabItem(icon: Icons.calendar_today_rounded, label: AppStrings.navMySchedule),
          _TabItem(icon: Icons.people_alt_rounded, label: AppStrings.patients),
          _TabItem(icon: Icons.settings_applications_rounded, label: AppStrings.navAdmin),
        ];
    }
  }
}
