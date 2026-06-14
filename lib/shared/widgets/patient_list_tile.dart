/// A unified patient list tile card with a person avatar icon, name, and combined
/// phone/location subtitle.
///
/// Enforces the Medics design pattern: teal CircleAvatar with Icons.person, bold
/// name, and combined phone and branch location subtitle.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// A standardized patient card list tile with person avatar, name, right-aligned branch,
/// and phone/last-visit subtitle.
class PatientListTile extends StatelessWidget {
  /// Creates a [PatientListTile].
  const PatientListTile({
    super.key,
    required this.name,
    required this.phone,
    required this.branchLabel,
    required this.lastVisitDate,
    this.trailing,
    this.onTap,
    this.avatarSize,
    this.margin,
  });

  /// The patient's full name.
  final String name;

  /// The patient's phone number.
  final String phone;

  /// The branch/clinic location label.
  final String branchLabel;

  /// The patient's last visit/appointment date.
  final DateTime? lastVisitDate;

  /// Optional additional trailing widget (displayed on the far right).
  final Widget? trailing;

  /// Called when the tile is tapped.
  final VoidCallback? onTap;

  /// Avatar diameter. Defaults to [AppSizes.avatarTile] (46px).
  final double? avatarSize;

  /// Optional external margin spacing around the tile card.
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final String lastVisitText = lastVisitDate != null
        ? DateFormat('MMM d').format(lastVisitDate!.toLocal())
        : '--';

    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: AppSizes.p12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        border: Border.all(
          color: AppColors.border,
          width: AppSizes.borderWidth,
        ),
        boxShadow: const [AppColors.cardShadow],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        child: Material(
          color: AppColors.surface,
          child: InkWell(
            onTap: onTap,
            splashColor: AppColors.primaryLight,
            borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.p16),
              child: Row(
                children: [
                  // ── Avatar ──
                  CircleAvatar(
                    radius: (avatarSize ?? AppSizes.avatarTile) / 2,
                    backgroundColor: AppColors.primary,
                    child: Icon(
                      Icons.person,
                      color: AppColors.textOnPrimary,
                      size: (avatarSize ?? AppSizes.avatarTile) * 0.5,
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: AppTextStyles.headingSmall.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSizes.p8),
                            Text(
                              branchLabel,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.p4),
                        Text.rich(
                          TextSpan(
                            children: [
                              const WidgetSpan(
                                child: Icon(
                                  Icons.phone,
                                  size: 14.0,
                                  color: AppColors.textSecondary,
                                ),
                                alignment: PlaceholderAlignment.middle,
                              ),
                              const WidgetSpan(child: SizedBox(width: AppSizes.p4)),
                              TextSpan(text: phone),
                              const TextSpan(text: '   •   '),
                              TextSpan(text: 'Last $lastVisitText'),
                            ],
                          ),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // ── Trailing ──
                  if (trailing != null) ...[
                    const SizedBox(width: AppSizes.p12),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
