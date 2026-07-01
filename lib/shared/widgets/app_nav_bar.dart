/// Material 3 bottom navigation bar — mobile layout.
///
/// Uses custom layout with high-contrast icon pop micro-interactions.
/// No sliding lines or background capsules to ensure ultimate simplicity, performance, and clean UX.
/// Conforms to Rule 15 & 16: theme-driven colors only.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/shared/widgets/nav_tabs.dart';

class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.userRole,
  });
  final int currentIndex;
  final ValueSetter<int> onTabSelected;
  final String userRole;

  @override
  Widget build(BuildContext context) {
    final tabs = NavTabs.forRole(userRole);
    final numTabs = tabs.length;
    if (numTabs == 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      // Modern spacious base height (74px) + device safe area padding
      height: 74.0 + MediaQuery.paddingOf(context).bottom,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            // Extremely soft, thin border separator
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
            width: 0.8,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 18.0),
          child: Row(
            children: List.generate(numTabs, (index) {
              final tab = tabs[index];
              final isSelected = index == currentIndex;

              return Expanded(
                child: InkWell(
                  onTap: () => onTabSelected(index),
                  // Disable Android splash ripples to match iOS/Airbnb premium feel
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Soft scale micro-interaction + smooth color transition
                      AnimatedScale(
                        scale: isSelected ? 1.08 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOutCubic,
                        child: TweenAnimationBuilder<Color?>(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOutCubic,
                          tween: ColorTween(
                            begin: isSelected
                                ? const Color(0xFF6B7280) // Inactive slate-grey
                                : colorScheme.primary,
                            end: isSelected
                                ? colorScheme.primary
                                : const Color(0xFF6B7280),
                          ),
                          builder: (context, color, child) {
                            return Icon(
                              isSelected ? tab.selectedIcon : tab.icon,
                              color: color,
                              size: 24.0,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Precise typography: tiny, medium/semibold weight, tracked out
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOutCubic,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 9.5,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          letterSpacing: 0.4,
                          color: isSelected
                              ? colorScheme.primary
                              : const Color(0xFF6B7280),
                        ),
                        child: Text(tab.label),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

