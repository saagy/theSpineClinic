/// Custom modal bottom sheet wrapper matching the Spine Clinic styling tokens.
///
/// Provides a top-rounded white bottom sheet scaffold with a cosmetic drag handle,
/// safe area tracking, keyboard padding protection, and close actions. Phone-only.
///
/// Rule 1 — keep files under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// A bottom sheet container styled with Spine Clinic design tokens.
class AppBottomSheet extends StatelessWidget {
  /// Creates an [AppBottomSheet].
  const AppBottomSheet({
    super.key,
    required this.title,
    required this.child,
  });

  /// Heading label for the modal context.
  final String title;

  /// Core content view displayed inside the bottom sheet.
  final Widget child;

  /// Scoped static utility to easily display this bottom sheet anywhere.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: AppColors.transparent, // Let Container handle styling shapes
      elevation: 0,
      builder: (context) => AppBottomSheet(
        title: title,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface, // Pure white background
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.r16), // Modern softer top radius
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: true, // Guard against hardware phone home-indicator notch overlaps
        child: Padding(
          // Pushes the bottom sheet up when the phone's soft keyboard is visible
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Wrap height around content tightly
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSizes.p8),
              // Centered cosmetic drag handle bar
              Center(
                child: Container(
                  width: AppSizes.handleWidth,
                  height: AppSizes.handleHeight,
                  decoration: const BoxDecoration(
                    color: AppColors.border, // Slate 200 cosmetic line
                    borderRadius: BorderRadius.all(Radius.circular(AppSizes.p2)),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.p8),
              // Header title and close button row layout
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.headingSmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.p12),
                    // Trailing close cross button
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.textSecondary,
                        size: AppSizes.iconDefault,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.p12),
              // Border line divider separating the header
              const Divider(
                height: AppSizes.borderWidth,
                thickness: AppSizes.borderWidth,
                color: AppColors.border,
              ),
              // Sheet body content block
              Padding(
                padding: const EdgeInsets.all(AppSizes.p16),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
