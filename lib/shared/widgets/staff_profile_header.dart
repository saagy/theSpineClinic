/// Unified staff profile header — initials avatar, bold name, role subtitle,
/// email + phone contact sub-rows, and a top-right edit pencil.
///
/// Replaces the horizontal label/value grid previously used by both the
/// doctor and receptionist profile screens. Touch-only interaction.
///
/// Rule 1 — under 200 lines.
/// Rule 7 — all strings via [AppStrings].
/// Rule 13 — `EdgeInsets.all(20)` and `BorderRadius.circular(16)`.
/// Rule 15/16 — colors resolved from [Theme.of(context).colorScheme]
///              plus static [AppColors] surface tokens.
/// Rule 17 — reuses [AppAvatar] for initials fallback.
/// Rule 20 — [AppAvatar] handles edge cases (digits, empty, single).
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/shared/widgets/app_avatar.dart';

/// Hero card showing the authenticated staff member's identity.
///
/// The card exposes [onEditProfile] which fires when the top-right
/// pencil icon is tapped.
class StaffProfileHeader extends StatelessWidget {
  /// Creates a [StaffProfileHeader].
  const StaffProfileHeader({
    super.key,
    required this.user,
    required this.roleLabel,
    required this.onEditProfile,
  });

  /// The authenticated staff profile.
  final Staff user;

  /// Pre-resolved human-readable role string (e.g. "Doctor").
  final String roleLabel;

  /// Callback fired when the user taps the edit pencil icon.
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ClinicColors clinic = ClinicColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        border: Border.all(color: cs.outline, width: AppSizes.borderWidth),
        boxShadow: [clinic.cardShadow],
      ),
      padding: const EdgeInsets.all(AppSizes.p20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAvatar(name: user.fullName, radius: 28),
              const SizedBox(width: AppSizes.p16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.fullName,
                      style: AppTextStyles.headingMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSizes.p4),
                    Text(
                      roleLabel,
                      style: AppTextStyles.bodySecondary.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEditProfile,
                tooltip: AppStrings.editProfileTooltip,
                icon: const Icon(Icons.edit_outlined, size: AppSizes.iconLarge),
                color: cs.onSurfaceVariant,
                splashRadius: AppSizes.tappableMin / 2,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p16),
          _ContactRow(
            icon: Icons.email_outlined,
            value: user.email,
            color: cs.onSurfaceVariant,
          ),
          if (user.phone != null && user.phone!.isNotEmpty) ...[
            const SizedBox(height: AppSizes.p6),
            _ContactRow(
              icon: Icons.phone_outlined,
              value: user.phone!,
              color: cs.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );
  }
}

/// Tight icon-and-text contact sub-row used inside [StaffProfileHeader].
class _ContactRow extends StatelessWidget {
  /// Creates an [_ContactRow].
  const _ContactRow({
    required this.icon,
    required this.value,
    required this.color,
  });

  /// Glyph rendered on the leading edge.
  final IconData icon;

  /// The text value displayed to the right of [icon].
  final String value;

  /// Foreground color for both the icon and the value text.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppSizes.iconSmall, color: color),
        const SizedBox(width: AppSizes.p8),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.body.copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
