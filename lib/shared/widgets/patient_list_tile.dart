/// A person-list row with circular initials avatar, name, subtitle,
/// and trailing badge.
///
/// Every patient, doctor, or staff member row uses this component.
/// It enforces the Medics design pattern: teal CircleAvatar, bold
/// name, muted gray subtitle, and an optional right-side status badge.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// A standardised person list tile with initials avatar.
class PatientListTile extends StatelessWidget {
  /// Creates a [PatientListTile].
  const PatientListTile({
    super.key,
    required this.name,
    this.subtitle,
    this.initials,
    this.trailing,
    this.onTap,
    this.avatarSize,
    this.statusBadge,
  });

  /// The person's full name (displayed in bold).
  final String name;

  /// Optional secondary line (e.g. phone, branch, last visit).
  final String? subtitle;

  /// Two-character initials for the avatar. Auto-derived from [name]
  /// if not provided.
  final String? initials;

  /// Optional widget on the right side (badge, icon, timestamp).
  final Widget? trailing;

  /// Optional [StatusBadge] or similar widget shown inline after the name.
  final Widget? statusBadge;

  /// Called when the tile is tapped.
  final VoidCallback? onTap;

  /// Avatar diameter. Defaults to [AppSizes.avatarTile] (46px).
  final double? avatarSize;

  @override
  Widget build(BuildContext context) {
    final String displayInitials = initials ?? _deriveInitials(name);

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSizes.borderRadiusCard,
        splashColor: AppColors.primaryLight,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p16,
            vertical: AppSizes.p14,
          ),
          child: Row(
            children: [
              // ── Avatar ──
              CircleAvatar(
                radius: (avatarSize ?? AppSizes.avatarTile) / 2,
                backgroundColor: AppColors.primary,
                child: Text(
                  displayInitials,
                  style: AppTextStyles.bodyBold.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.p12),

              // ── Text content ──
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: AppTextStyles.bodyBold,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (statusBadge != null) ...[
                          const SizedBox(width: AppSizes.p8),
                          statusBadge!,
                        ],
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSizes.p2),
                      Text(
                        subtitle!,
                        style: AppTextStyles.bodySecondary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // ── Trailing ──
              if (trailing != null) ...[
                const SizedBox(width: AppSizes.p8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Derives up to two initials from a name string.
  String _deriveInitials(String name) {
    final List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.isNotEmpty
          ? parts.first[0].toUpperCase()
          : '?';
    }
    final String first = parts.first.isNotEmpty
        ? parts.first[0].toUpperCase()
        : '';
    final String last = parts.last.isNotEmpty
        ? parts.last[0].toUpperCase()
        : '';
    return '$first$last';
  }
}
