/// Floating capsule island navigation bar powered by [GNav].
///
/// Detached from screen edges with rounded corners, soft shadow, and
/// smooth pill-style active tab indicator. Role-driven tabs.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';

/// A floating capsule bottom navigation bar using the google_nav_bar package.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentTabIndex,
    required this.onTabSelected,
    required this.userRole,
  });
  final int currentTabIndex;
  final ValueSetter<int> onTabSelected;
  final String userRole;

  static const Color _activeColor = Color(0xFF085041);
  static const Color _activeBg = Color(0xFFE1F5EE);

  @override
  Widget build(BuildContext context) {
    final tabs = _resolveTabs(userRole);

    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: GNav(
        selectedIndex: currentTabIndex,
        onTabChange: onTabSelected,
        rippleColor: Colors.grey[300]!,
        hoverColor: Colors.grey[100]!,
        gap: 8,
        activeColor: _activeColor,
        iconSize: 22,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        duration: const Duration(milliseconds: 300),
        tabBackgroundColor: _activeBg,
        color: Colors.grey,
        tabBorderRadius: 30,
        tabs: tabs
            .map((t) => GButton(icon: t.icon, text: t.label))
            .toList(),
      ),
    );
  }

  List<_Tab> _resolveTabs(String role) {
    switch (role) {
      case 'doctor':
        return const [
          _Tab(icon: Icons.calendar_today_outlined, label: AppStrings.navMySchedule),
          _Tab(icon: Icons.people_outline, label: AppStrings.navMyPatients),
          _Tab(icon: Icons.person_outline, label: AppStrings.profile),
        ];
      case 'super_admin':
        return const [
          _Tab(icon: Icons.analytics_outlined, label: AppStrings.navAnalytics),
          _Tab(icon: Icons.calendar_today_outlined, label: AppStrings.navAppts),
          _Tab(icon: Icons.calendar_today_outlined, label: AppStrings.navMySchedule),
          _Tab(icon: Icons.people_outline, label: AppStrings.patients),
          _Tab(icon: Icons.settings_outlined, label: AppStrings.navAdmin),
        ];
      case 'receptionist':
      default:
        return const [
          _Tab(icon: Icons.calendar_today_outlined, label: AppStrings.navAppts),
          _Tab(icon: Icons.people_outline, label: AppStrings.patients),
          _Tab(icon: Icons.person_outline, label: AppStrings.profile),
        ];
    }
  }
}

class _Tab {
  const _Tab({required this.icon, required this.label});
  final IconData icon;
  final String label;
}
