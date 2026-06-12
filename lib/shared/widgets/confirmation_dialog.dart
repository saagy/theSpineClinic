/// Custom confirmation dialog widget matching the Spine Clinic styling tokens.
///
/// A reusable dialog overlay invoked during destructive or critical operations,
/// returning a boolean result via Navigator.pop. Touch-only design.
///
/// Rule 1 — keep files under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';

/// A modal dialog wrapper for critical confirmation checks styled with design tokens.
class ConfirmationDialog extends StatelessWidget {
  /// Creates a [ConfirmationDialog].
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = AppStrings.confirm,
    this.cancelLabel = AppStrings.cancel,
    this.isDestructive = false,
  });

  /// Heading for the confirmation alert.
  final String title;

  /// Descriptive context explaining the consequences of the action.
  final String message;

  /// Text label for the confirmation button.
  final String confirmLabel;

  /// Text label for the cancellation/back-out button.
  final String cancelLabel;

  /// If true, the confirm button uses the danger (Rose 600) variant.
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface, // Pure white background
      surfaceTintColor: AppColors.transparent, // Disable Material 3 overlay tinting
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.r8)), // Max standard card radius
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p24, // Symmetrical screen edge margins
      ),
      contentPadding: const EdgeInsets.all(AppSizes.p24), // Uniform content padding
      title: Text(
        title,
        style: AppTextStyles.headingSmall.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
      content: Text(
        message,
        style: AppTextStyles.body.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      actionsPadding: const EdgeInsets.only(
        right: AppSizes.p24,
        bottom: AppSizes.p24,
        left: AppSizes.p24,
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Cancel button (always secondary style)
            AppButton(
              labelText: cancelLabel,
              onPressed: () => Navigator.of(context).pop(false),
              variant: AppButtonVariant.secondary,
              fullWidth: false,
            ),
            const SizedBox(width: AppSizes.p12), // 12px compact action separation
            // Confirm button (primary or danger based on parameter)
            AppButton(
              labelText: confirmLabel,
              onPressed: () => Navigator.of(context).pop(true),
              variant: isDestructive ? AppButtonVariant.danger : AppButtonVariant.primary,
              fullWidth: false,
            ),
          ],
        ),
      ],
    );
  }
}
