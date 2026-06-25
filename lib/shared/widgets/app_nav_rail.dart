/// Collapsible side-navigation sidebar — desktop/wide layout.
///
/// Toggles between expanded (240px) and collapsed (64px) states locally.
/// Conforms to Rule 15 & 16: theme-driven colors only.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/shared/widgets/nav_tabs.dart';

class AppNavRail extends StatefulWidget {
  const AppNavRail({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.userRole,
  });

  final int currentIndex;
  final ValueSetter<int> onTabSelected;
  final String userRole;

  @override
  State<AppNavRail> createState() => _AppNavRailState();
}

class _AppNavRailState extends State<AppNavRail> {
  bool _isCollapsed = false;

  static const double _logoHeight = 64.0;
  static const double _itemHeight = 56.0;

  @override
  Widget build(BuildContext context) {
    final tabs = NavTabs.forRole(widget.userRole);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final double sidebarWidth = _isCollapsed ? 64.0 : AppSizes.navDrawerWidth;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: colorScheme.outlineVariant,
            width: AppSizes.borderWidth,
          ),
        ),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo Section
            SizedBox(
              height: _logoHeight,
              child: _isCollapsed
                  ? Center(child: _Logo())
                  : Row(
                      children: [
                        const SizedBox(width: AppSizes.p16),
                        _Logo(),
                        const SizedBox(width: AppSizes.p12),
                        const Expanded(child: _LogoText()),
                        const SizedBox(width: AppSizes.p16),
                      ],
                    ),
            ),
            const SizedBox(height: AppSizes.p16),
            // Navigation Items
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: tabs.length,
                itemExtent: _itemHeight,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final tab = tabs[index];
                  final isSelected = index == widget.currentIndex;

                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSizes.p8,
                      vertical: AppSizes.p2,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primaryContainer.withAlpha(120)
                          : Colors.transparent,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(AppSizes.r8),
                      ),
                    ),
                    child: InkWell(
                      onTap: () => widget.onTabSelected(index),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(AppSizes.r8),
                      ),
                      splashColor: colorScheme.primary.withAlpha(20),
                      highlightColor: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.p12,
                          vertical: AppSizes.p8,
                        ),
                        child: Row(
                          mainAxisAlignment: _isCollapsed
                              ? MainAxisAlignment.center
                              : MainAxisAlignment.start,
                          children: [
                            // Icon pop and color transition
                            AnimatedScale(
                              scale: isSelected ? 1.08 : 1.0,
                              duration: const Duration(milliseconds: 180),
                              curve: isSelected
                                  ? Curves.easeOutBack
                                  : Curves.easeOutCubic,
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
                            if (!_isCollapsed) ...[
                              const SizedBox(width: AppSizes.p12),
                              Expanded(
                                child: Text(
                                  tab.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.clip,
                                  softWrap: false,
                                  style: (isSelected
                                          ? AppTextStyles.bodyBold
                                          : AppTextStyles.bodyMedium)
                                      .copyWith(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Collapse Toggle at Bottom
            Container(
              margin: const EdgeInsets.all(AppSizes.p8),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.transparent,
                  ),
                ),
              ),
              child: InkWell(
                onTap: () => setState(() => _isCollapsed = !_isCollapsed),
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppSizes.r8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.p12),
                  child: Row(
                    mainAxisAlignment: _isCollapsed
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    children: [
                      const SizedBox(width: AppSizes.p4),
                      Icon(
                        _isCollapsed
                            ? Icons.chevron_right_rounded
                            : Icons.chevron_left_rounded,
                        color: colorScheme.onSurfaceVariant,
                        size: AppSizes.iconDefault,
                      ),
                      if (!_isCollapsed) ...[
                        const SizedBox(width: AppSizes.p12),
                        Text(
                          AppStrings.collapse,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: AppSizes.iconLarge + AppSizes.p4,
      height: AppSizes.iconLarge + AppSizes.p4,
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(AppSizes.r8),
      ),
      child: Icon(
        Icons.spa_rounded,
        color: cs.onPrimary,
        size: AppSizes.iconDefault,
      ),
    );
  }
}

class _LogoText extends StatelessWidget {
  const _LogoText();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.appName,
          maxLines: 1,
          overflow: TextOverflow.clip,
          softWrap: false,
          style: AppTextStyles.headingSmall,
        ),
        Text(
          AppStrings.appTagline,
          maxLines: 1,
          overflow: TextOverflow.clip,
          softWrap: false,
          style: AppTextStyles.caption.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
