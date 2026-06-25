/// Compact settings menu row used inside profile/account surfaces.
///
/// Wraps [DataListTile] with sensible defaults for the profile-style
/// one-line directory list:
/// - Transparent background (no card chrome) so rows visually stack
///   on the canvas without double-card nesting.
/// - Default trailing chevron.
/// - Optional destructive styling for sign-out / destructive actions.
///
/// Rule 1 — under 200 lines.
/// Rule 11 — [DataListTile]'s built-in [InkWell] provides immediate
///           touch feedback with no hover/MouseRegion patterns.
/// Rule 13 — radius and padding inherited from [DataListTile].
/// Rule 15/16 — colors resolved from [Theme.of(context).colorScheme].
/// Rule 17 — built on top of [DataListTile]; no visual primitive
///           reinvented.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/shared/widgets/data_list_tile.dart';

/// A profile-style menu row that wraps [DataListTile] with the
/// background-default `onSurface` color scheme and (optionally) a
/// destructive color treatment.
class ProfileMenuRow extends StatelessWidget {
  /// Creates a [ProfileMenuRow].
  const ProfileMenuRow({
    super.key,
    required this.title,
    required this.leadingIcon,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
  });

  /// The bold row label rendered next to [leadingIcon].
  final String title;

  /// Glyph rendered on the leading edge.
  final IconData leadingIcon;

  /// Optional secondary line rendered under [title].
  final String? subtitle;

  /// Optional widget rendered on the trailing edge. Defaults to a
  /// right-pointing chevron.
  final Widget? trailing;

  /// Callback invoked when the row is tapped. When null the row
  /// renders without ripple feedback.
  final VoidCallback? onTap;

  /// If true, the leading icon and title text adopt the theme's
  /// error color and the row keeps a transparent background.
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color accent = isDestructive ? cs.error : cs.onSurface;

    return DataListTile(
      transparent: true,
      onTap: onTap,
      margin: EdgeInsets.zero,
      leading: Icon(
        leadingIcon,
        size: AppSizes.iconDefault,
        color: accent,
      ),
      titleStyle: AppTextStyles.bodyBold.copyWith(color: accent),
      subtitleStyle: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
      trailing: trailing ??
          Icon(
            Icons.chevron_right_rounded,
            size: AppSizes.iconDefault,
            color: cs.onSurfaceVariant,
          ),
      title: title,
      subtitle: subtitle,
    );
  }
}
