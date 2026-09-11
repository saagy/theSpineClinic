/// Collapsible side-navigation sidebar — desktop/wide layout.
///
/// Toggles between expanded (240px) and collapsed (64px) states locally.
/// Conforms to Rule 15 & 16: theme-driven colors only.
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/brand_vectors.dart';
import 'package:spine_clinic_app/shared/widgets/nav_rail_tile.dart';
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
    final Color transparent = colorScheme.surface.withAlpha(0);
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
            // Branded Logo Section
            SizedBox(
              height: _logoHeight,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final showExpanded =
                      !_isCollapsed && constraints.maxWidth > 100;
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: showExpanded
                        ? const Padding(
                            key: ValueKey('expanded_brand_logo'),
                            padding:
                                EdgeInsets.symmetric(horizontal: AppSizes.p20),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _ExpandedBrandLogo(),
                            ),
                          )
                        : const Center(
                            key: ValueKey('collapsed_brand_mark'),
                            child: _CollapsedBrandMark(),
                          ),
                  );
                },
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
                  return NavRailTile(
                    tab: tabs[index],
                    isSelected: index == widget.currentIndex,
                    isCollapsed: _isCollapsed,
                    onTap: () => widget.onTabSelected(index),
                  );
                },
              ),
            ),
            // Collapse Toggle at Bottom
            Container(
              margin: const EdgeInsets.all(AppSizes.p8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: transparent,
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final showText =
                          !_isCollapsed && constraints.maxWidth > 100;
                      return Row(
                        mainAxisAlignment: showText
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.center,
                        children: [
                          if (showText) const SizedBox(width: AppSizes.p4),
                          Icon(
                            _isCollapsed
                                ? Icons.chevron_right_rounded
                                : Icons.chevron_left_rounded,
                            color: colorScheme.onSurfaceVariant,
                            size: AppSizes.iconDefault,
                          ),
                          if (showText) ...[
                            const SizedBox(width: AppSizes.p12),
                            Expanded(
                              child: Text(
                                AppStrings.collapse,
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                softWrap: false,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
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

class _CollapsedBrandMark extends StatelessWidget {
  const _CollapsedBrandMark();

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
      padding: const EdgeInsets.all(AppSizes.p6),
      child: SvgPicture.string(
        spineEmblemSvg,
        colorFilter: ColorFilter.mode(
          cs.onPrimary,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}

class _ExpandedBrandLogo extends StatelessWidget {
  const _ExpandedBrandLogo();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SvgPicture.string(
      spineLogoSvg,
      width: 140,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(
        cs.primary,
        BlendMode.srcIn,
      ),
    );
  }
}
