/// Shared navigation tab configuration — role-driven destinations.
///
/// Both [AppNavBar] and [AppNavRail] consume this single source of truth.
/// M3 convention: outlined icon (unselected) -> filled icon (selected).
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';

/// A single navigation destination with unselected/selected icon states.
class NavTab {
  const NavTab({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Resolves the navigation tab set for a given [userRole].
abstract final class NavTabs {
  static List<NavTab> forRole(String role) => switch (role) {
        'doctor' => const [
            NavTab(
              icon: Icons.calendar_today_outlined,
              selectedIcon: Icons.calendar_today,
              label: AppStrings.navMySchedule,
            ),
            NavTab(
              icon: Icons.people_outline,
              selectedIcon: Icons.people,
              label: AppStrings.navMyPatients,
            ),
            NavTab(
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
              label: AppStrings.profile,
            ),
          ],
        'super_admin' => const [
            NavTab(
              icon: Icons.analytics_outlined,
              selectedIcon: Icons.analytics,
              label: AppStrings.navAnalytics,
            ),
            NavTab(
              icon: Icons.calendar_today_outlined,
              selectedIcon: Icons.calendar_today,
              label: AppStrings.navAppts,
            ),
            NavTab(
              icon: Icons.calendar_today_outlined,
              selectedIcon: Icons.calendar_today,
              label: AppStrings.navMySchedule,
            ),
            NavTab(
              icon: Icons.people_outline,
              selectedIcon: Icons.people,
              label: AppStrings.patients,
            ),
            NavTab(
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings,
              label: AppStrings.navAdmin,
            ),
          ],
        _ => const [
            NavTab(
              icon: Icons.calendar_today_outlined,
              selectedIcon: Icons.calendar_today,
              label: AppStrings.navAppts,
            ),
            NavTab(
              icon: Icons.people_outline,
              selectedIcon: Icons.people,
              label: AppStrings.patients,
            ),
            NavTab(
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
              label: AppStrings.profile,
            ),
          ],
      };
}
