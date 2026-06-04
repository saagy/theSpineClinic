/// Custom error display widget matching the Spine Clinic design tokens.
///
/// Centrally displays a normalized exception with its human-readable message,
/// an alert icon, and an optional retry action button.
///
/// Rule 1 — keep files under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';

/// A centered layout displaying AppException details and a retry action button.
class ErrorView extends StatelessWidget {
  /// Creates an [ErrorView].
  const ErrorView({
    super.key,
    required this.exception,
    this.onRetry,
  });

  /// The normalized application exception to display.
  final AppException exception;

  /// Optional callback to re-trigger the failed operation.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    // Resolve the user-facing string safely using the translation fallback dictionary
    final String errorMessage = AppStrings.fromKey(exception.userMessageKey);

    return Center(
      child: Padding(
        padding: AppSizes.paddingScreenH,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Line-art alert icon colored in AppColors.error
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: AppSizes.iconLarge + AppSizes.p16, // ~40px icon
            ),
            const SizedBox(height: AppSizes.p16),
            // Header label
            Text(
              AppStrings.errorUnknown, // "An unexpected error occurred" style header
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.p8),
            // Descriptive error message
            Text(
              errorMessage,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSizes.p24),
              // Compact retry button centered below content
              AppButton(
                labelText: AppStrings.retry,
                onPressed: onRetry,
                variant: AppButtonVariant.secondary,
                fullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
