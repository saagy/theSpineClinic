/// Shared navigation tab configuration — role-driven destinations.
///
/// Both [AppNavBar] and [AppNavRail] consume this single source of truth.
/// Conforms to modern clean typography and iconography guidelines.
library;

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';

/// A single navigation destination with unselected/selected icon states.
class NavTab {
  const NavTab({
    required this.icon,
    IconData? selectedIcon,
    required this.label,
  }) : selectedIcon = selectedIcon ?? icon;

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Resolves the navigation tab set for a given [userRole].
abstract final class NavTabs {
  static List<NavTab> forRole(String role) => switch (role) {
        'doctor' => const [
            NavTab(
              icon: LucideIcons.calendar,
              label: AppStrings.navMySchedule,
            ),
            NavTab(
              icon: LucideIcons.users,
              label: AppStrings.navMyPatients,
            ),
            NavTab(
              icon: LucideIcons.user,
              label: AppStrings.profile,
            ),
          ],
        'super_admin' => const [
            NavTab(
              icon: LucideIcons.trending_up,
              label: AppStrings.navAnalytics,
            ),
            NavTab(
              icon: LucideIcons.calendar_check,
              label: AppStrings.navAppts,
            ),
            NavTab(
              icon: LucideIcons.calendar,
              label: AppStrings.navMySchedule,
            ),
            NavTab(
              icon: LucideIcons.users,
              label: AppStrings.patients,
            ),
            NavTab(
              icon: LucideIcons.settings,
              label: AppStrings.navAdmin,
            ),
          ],
        _ => const [
            NavTab(
              icon: LucideIcons.calendar_check,
              label: AppStrings.navAppts,
            ),
            NavTab(
              icon: LucideIcons.users,
              label: AppStrings.patients,
            ),
            NavTab(
              icon: LucideIcons.user,
              label: AppStrings.profile,
            ),
          ],
      };
}

