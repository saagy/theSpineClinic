/// Material 3 bottom navigation bar — mobile layout.
///
/// Uses custom layout with high-contrast icon pop micro-interactions.
/// No sliding lines or background capsules to ensure ultimate simplicity, performance, and clean UX.
/// Conforms to Rule 15 & 16: theme-driven colors only.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
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

    return Container(
      height: AppSizes.bottomNavHeight + MediaQuery.paddingOf(context).bottom,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant,
            width: AppSizes.borderWidth,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Row(
          children: List.generate(numTabs, (index) {
            final tab = tabs[index];
            final isSelected = index == currentIndex;

            return Expanded(
              child: InkWell(
                onTap: () => onTabSelected(index),
                splashColor: colorScheme.primary.withAlpha(20),
                highlightColor: Colors.transparent,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Scale micro-interaction + smooth color transition
                    AnimatedScale(
                      scale: isSelected ? 1.12 : 1.0,
                      duration: const Duration(milliseconds: 180),
                      curve: isSelected ? Curves.easeOutBack : Curves.easeOutCubic,
                      child: TweenAnimationBuilder<Color?>(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        tween: ColorTween(
                          begin: isSelected
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.primary,
                          end: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        builder: (context, color, child) {
                          return Icon(
                            isSelected ? tab.selectedIcon : tab.icon,
                            color: color,
                            size: AppSizes.iconDefault,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSizes.p4),
                    // Text transition
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      style: (isSelected
                              ? AppTextStyles.captionBold
                              : AppTextStyles.caption)
                          .copyWith(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
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
    );
  }
}
