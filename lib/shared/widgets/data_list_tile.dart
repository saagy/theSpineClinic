/// Custom high-density list tile widget matching the Spine Clinic styling tokens.
///
/// Designed as the ultimate polymorphic tabular list cell to replace patient,
/// appointment, and staff rows on compact phone layouts. Touch-interactive.
///
/// Rule 1 — keep files under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// A high-density data row tile styled with Spine Clinic design tokens.
class DataListTile extends StatelessWidget {
  /// Creates a [DataListTile].
  const DataListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.transparent = false,
  });

  /// The primary textual descriptor of this row cell.
  final String title;

  /// Optional secondary label rendered below the title.
  final String? subtitle;

  /// Optional widget rendered on the leading edge (e.g. badge, icon).
  final Widget? leading;

  /// Optional widget rendered on the trailing edge (e.g. arrow, badge).
  final Widget? trailing;

  /// Optional callback triggered when the row is tapped.
  final VoidCallback? onTap;

  /// If true, uses transparent background instead of AppColors.surface.
  final bool transparent;

  @override
  Widget build(BuildContext context) {
    final Widget cellContent = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p12, // Compact 12px horizontal padding
        vertical: AppSizes.p8,    // High-density 8px vertical padding
      ),
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
                Text(
                  title,
                  style: AppTextStyles.bodyBold.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSizes.p2),
                  Text(
                    subtitle!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

    // Decorate the tile container with bottom separator line
    final Widget tileContainer = Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border, // Slate 200 thin bottom separator border
            width: AppSizes.borderWidth,
          ),
        ),
      ),
      child: Material(
        color: transparent ? Colors.transparent : AppColors.surface,
        child: onTap != null
            ? InkWell(
                onTap: onTap,
                // Match the visual theme with Slate 50 touch highlight tint
                splashColor: AppColors.background,
                highlightColor: AppColors.background.withAlpha(128),
                child: cellContent,
              )
            : cellContent,
      ),
    );

    return tileContainer;
  }
}
