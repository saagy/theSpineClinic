/// Custom high-density list tile widget matching the Spine Clinic styling tokens.
///
/// Designed as the ultimate polymorphic tabular list cell to replace patient,
/// appointment, and staff rows on compact phone layouts. Touch-interactive.
///
/// Rule 1 — keep files under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';

/// A high-density data row tile styled with Spine Clinic design tokens.
class DataListTile extends StatelessWidget {
  /// Creates a [DataListTile].
  const DataListTile({
    super.key,
    this.title = '',
    this.titleWidget,
    this.subtitle,
    this.subtitleWidget,
    this.leading,
    this.trailing,
    this.onTap,
    this.transparent = false,
    this.margin,
    this.titleStyle,
    this.subtitleStyle,
    this.titleMaxLines,
    this.subtitleMaxLines,
  });

  /// Max lines for the title text. Defaults to 1. Set to `null` for unlimited.
  final int? titleMaxLines;

  /// Max lines for the subtitle text. Defaults to 1. Set to `null` for unlimited.
  final int? subtitleMaxLines;

  /// The primary textual descriptor of this row cell.
  final String title;

  /// Optional custom widget to render in place of the title text.
  final Widget? titleWidget;

  /// Optional secondary label rendered below the title.
  final String? subtitle;

  /// Optional custom widget rendered in place of the subtitle text.
  /// Takes precedence over [subtitle] when both are provided.
  final Widget? subtitleWidget;

  /// Optional widget rendered on the leading edge (e.g. badge, icon).
  final Widget? leading;

  /// Optional widget rendered on the trailing edge (e.g. arrow, badge).
  final Widget? trailing;

  /// Optional callback triggered when the row is tapped.
  final VoidCallback? onTap;

  /// If true, uses transparent background instead of AppColors.surface.
  final bool transparent;

  /// Optional custom margin spacing around the tile card.
  final EdgeInsetsGeometry? margin;

  /// Optional style override for the title text.
  final TextStyle? titleStyle;

  /// Optional style override for the subtitle text.
  final TextStyle? subtitleStyle;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ClinicColors clinic = ClinicColors.of(context);
    final Widget cellContent = Padding(
      padding: const EdgeInsets.all(
        AppSizes.p16,
      ), // Comfortable touch-padding (Rule 13)
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppSizes.p12),
          ],
          // Expanded wrapper forces column to take up remaining space, preventing overflow
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                titleWidget ??
                    Text(
                      title,
                      style:
                          titleStyle ??
                          AppTextStyles.bodyBold.copyWith(color: cs.onSurface),
                      maxLines: titleMaxLines ?? 1,
                      softWrap: true,
                      overflow: titleMaxLines == null
                          ? null
                          : TextOverflow.ellipsis,
                    ),
                if (subtitleWidget != null) ...[
                  const SizedBox(height: AppSizes.p2),
                  subtitleWidget!,
                ] else if (subtitle != null) ...[
                  const SizedBox(height: AppSizes.p2),
                  Text(
                    subtitle!,
                    style:
                        subtitleStyle ??
                        AppTextStyles.caption.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                    maxLines: subtitleMaxLines ?? 1,
                    softWrap: true,
                    overflow: subtitleMaxLines == null
                        ? null
                        : TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSizes.p12),
            trailing!,
          ],
        ],
      ),
    );

    // Decorate the tile container as an M3 Card (Rule 13)
    final Widget tileContainer = Container(
      margin:
          margin ??
          (transparent
              ? EdgeInsets.zero
              : const EdgeInsets.only(bottom: AppSizes.p12)),
      decoration: transparent
          ? const BoxDecoration()
          : BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.all(
                Radius.circular(AppSizes.r16),
              ),
              border: Border.all(
                color: cs.outline,
                width: AppSizes.borderWidth,
              ),
              boxShadow: [clinic.cardShadow],
            ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        child: Material(
          color: transparent ? Colors.transparent : cs.surface,
          child: onTap != null
              ? InkWell(
                  onTap: onTap,
                  splashColor: cs.surfaceContainer,
                  highlightColor: cs.surfaceContainer.withAlpha(128),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(AppSizes.r16),
                  ),
                  child: cellContent,
                )
              : cellContent,
        ),
      ),
    );

    return tileContainer;
  }
}
