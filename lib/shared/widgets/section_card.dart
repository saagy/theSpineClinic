/// Custom card layout widget matching the Stripe Dashboard design tokens.
///
/// Serves as the foundational container wrapper for lists, details, profiles,
/// and form blocks, featuring an optional header row with trailing actions.
///
/// Rule 1 — keep files under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// A flat surface container card styled with Spine Clinic design tokens.
class SectionCard extends StatelessWidget {
  /// Creates a [SectionCard].
  const SectionCard({
    super.key,
    required this.child,
    this.title,
    this.action,
  });

  /// The main body content inside the card.
  final Widget child;

  /// Optional section title text rendered in the header.
  final String? title;

  /// Optional widget rendered on the right side of the header.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final bool hasHeader = title != null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface, // Pure white background
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r8)), // Max standard container radius
        border: Border.all(
          color: AppColors.border, // Slate 200 crisp lines
          width: AppSizes.borderWidth,
        ),
        boxShadow: const [AppColors.cardShadow], // Stripe bottom micro-shadow
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasHeader) ...[
            // Header layout container block
            Padding(
              padding: const EdgeInsets.only(
                left: AppSizes.p16,
                right: AppSizes.p16,
                top: AppSizes.p16,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: AppTextStyles.headingSmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (action != null) ...[
                    const SizedBox(width: AppSizes.p12),
                    action!,
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSizes.p12),
            // Minimalist horizontal grid line divider
            const Divider(
              height: AppSizes.borderWidth,
              thickness: AppSizes.borderWidth,
              color: AppColors.border,
            ),
          ],
          // Card body content padding alignment
          Padding(
            padding: EdgeInsets.only(
              left: AppSizes.p16,
              right: AppSizes.p16,
              bottom: AppSizes.p16,
              // If there's a header, top padding is covered by the header/divider gap
              top: hasHeader ? AppSizes.p16 : AppSizes.p16,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
