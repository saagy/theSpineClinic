/// Custom confirmation dialog widget matching the Spine Clinic styling tokens.
///
/// A reusable dialog overlay invoked during destructive or critical operations,
/// returning a boolean result via Navigator.pop.
///
/// Rule 1 — keep files under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

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
    final ColorScheme cs = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: cs.surface,
      surfaceTintColor: cs.surface.withAlpha(0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.r16)), // Modern card radius
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p24, // Symmetrical screen edge margins
      ),
      contentPadding: const EdgeInsets.all(AppSizes.p24), // Uniform content padding
      title: Text(title, style: AppTextStyles.headingSmall.copyWith(color: cs.onSurface)),
      content: Text(message, style: AppTextStyles.body.copyWith(color: cs.onSurfaceVariant)),
      actionsPadding: const EdgeInsets.only(right: AppSizes.p24, bottom: AppSizes.p24, left: AppSizes.p24),
      actions: [
        Wrap(
          alignment: WrapAlignment.end,
          spacing: AppSizes.p12,
          runSpacing: AppSizes.p8,
          children: [
            // Cancel button (always secondary style)
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(minimumSize: const Size(AppSizes.tappableMin, AppSizes.tappableMin)),
              child: Text(cancelLabel, style: AppTextStyles.button),
            ),
            // Confirm button (primary or danger based on parameter)
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                minimumSize: const Size(AppSizes.tappableMin, AppSizes.tappableMin),
                backgroundColor: isDestructive ? cs.error : null,
                foregroundColor: isDestructive ? cs.onError : null,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r8)),
              ),
              child: Text(confirmLabel, style: AppTextStyles.button),
            ),
          ],
        ),
      ],
    );
  }
}
