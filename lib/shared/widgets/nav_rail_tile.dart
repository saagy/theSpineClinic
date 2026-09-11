import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/shared/widgets/nav_tabs.dart';

/// Single item tile inside [AppNavRail].
///
/// Handles icon scale micro-interaction, color tweening, and label visibility.
class NavRailTile extends StatelessWidget {
  const NavRailTile({
    super.key,
    required this.tab,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
  });

  final NavTab tab;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final Color transparent = colorScheme.surface.withAlpha(0);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.p8,
        vertical: AppSizes.p2,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primaryContainer.withAlpha(120)
            : transparent,
        borderRadius: const BorderRadius.all(
          Radius.circular(AppSizes.r8),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(
          Radius.circular(AppSizes.r8),
        ),
        splashColor: colorScheme.primary.withAlpha(20),
        highlightColor: transparent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showLabel = !isCollapsed && constraints.maxWidth > 100;

            final iconWidget = AnimatedScale(
              scale: isSelected ? 1.08 : 1.0,
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
            );

            if (!showLabel) {
              return Center(child: iconWidget);
            }

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.p12,
                vertical: AppSizes.p8,
              ),
              child: Row(
                children: [
                  iconWidget,
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
              ),
            );
          },
        ),
      ),
    );
  }
}
