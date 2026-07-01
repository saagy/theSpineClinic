/// Shared doctor row — avatar, name, optional deactivated badge,
/// optional subtitle (e.g. "Covering Dr. X").
///
/// Used by both appointment detail and patient info tab.
/// When [isActive] is false, the row dims to 50% opacity and shows
/// a "Deactivated" badge inline.
///
/// Rule 15/16 — colours via Theme.of(context).colorScheme.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/shared/widgets/app_avatar.dart';

class DoctorRow extends StatelessWidget {
  const DoctorRow({
    super.key,
    required this.name,
    this.isActive = true,
    this.subtitle,
    this.badgeLabel,
    this.radius = 18,
  });

  final String name;
  final bool isActive;
  final String? subtitle;
  final String? badgeLabel;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bool showDeactivated = !isActive;

    return Opacity(
      opacity: showDeactivated ? 0.5 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.p6),
        child: Row(
          children: [
            AppAvatar(name: name, radius: radius),
            const SizedBox(width: AppSizes.p8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: AppTextStyles.bodyBold,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (showDeactivated) ...[
                        const SizedBox(width: AppSizes.p6),
                        _Badge(
                          label: AppStrings.deactivated,
                          bg: cs.onSurface.withValues(alpha: 0.08),
                          fg: cs.onSurface.withValues(alpha: 0.6),
                        ),
                      ],
                      if (badgeLabel != null) ...[
                        const SizedBox(width: AppSizes.p6),
                        _Badge(
                          label: badgeLabel!,
                          bg: cs.tertiaryContainer,
                          fg: cs.tertiary,
                        ),
                      ],
                    ],
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSizes.p2),
                      child: Text(
                        subtitle!,
                        style: AppTextStyles.caption.copyWith(
                          color: cs.tertiary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.bg, required this.fg});
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}
