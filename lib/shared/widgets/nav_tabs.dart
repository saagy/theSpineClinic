/// Shared navigation tab configuration — role-driven destinations.
///
/// Both [AppNavBar] and [AppNavRail] consume this single source of truth.
/// Conforms to modern clean typography and iconography guidelines.
library;

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';

/// A single navigation destination with unselected/selected icon states.
class NavTab {
  const NavTab({
    required this.icon,
    IconData? selectedIcon,
    required this.label,
    required this.path,
  }) : selectedIcon = selectedIcon ?? icon;

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String path;
}

/// Resolves the navigation tab set for a given [userRole].
abstract final class NavTabs {
  static List<NavTab> forRole(String role, {bool showBilling = false}) =>
      switch (role) {
        'senior_doctor' => const [
          NavTab(
            icon: LucideIcons.calendar,
            label: AppStrings.navMySchedule,
            path: AppRoutes.schedule,
          ),
          NavTab(
            icon: LucideIcons.users,
            label: AppStrings.patients,
            path: AppRoutes.patientList,
          ),
          NavTab(
            icon: LucideIcons.user,
            label: AppStrings.profile,
            path: AppRoutes.doctorProfile,
          ),
        ],
        'doctor' => const [
          NavTab(
            icon: LucideIcons.calendar,
            label: AppStrings.navMySchedule,
            path: AppRoutes.schedule,
          ),
          NavTab(
            icon: LucideIcons.users,
            label: AppStrings.navMyPatients,
            path: AppRoutes.myPatients,
          ),
          NavTab(
            icon: LucideIcons.user,
            label: AppStrings.profile,
            path: AppRoutes.doctorProfile,
          ),
        ],
        'super_admin' => const [
          _appointments,
          _patients,
          NavTab(
            icon: LucideIcons.settings,
            label: AppStrings.navAdmin,
            path: AppRoutes.adminHub,
          ),
        ],
        _ => [
          _appointments,
          _patients,
          if (role == 'receptionist' && showBilling)
            NavTab(
              icon: LucideIcons.receipt,
              label: AppStrings.billing.title,
              path: AppRoutes.billing,
            ),
          const NavTab(
            icon: LucideIcons.user,
            label: AppStrings.profile,
            path: AppRoutes.receptionistProfile,
          ),
        ],
      };

  static const _appointments = NavTab(
    icon: LucideIcons.calendar_check,
    label: AppStrings.navAppts,
    path: AppRoutes.allAppointments,
  );
  static const _patients = NavTab(
    icon: LucideIcons.users,
    label: AppStrings.patients,
    path: AppRoutes.patientList,
  );
}
