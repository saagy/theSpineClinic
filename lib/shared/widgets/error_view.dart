/// Custom error display widget matching the Medics design tokens.
///
/// Centrally displays a normalized exception with its human-readable
/// message, a large tinted alert icon in a soft circle, and an optional
/// retry action.
///
/// All colours are resolved from [Theme.of(context).colorScheme] for
/// automatic dark-mode compatibility.
///
/// Rule 1 — keep files under 200 lines.
/// Rule 16 — zero hardcoded colours, all via theme.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';

/// A centered layout displaying AppException details and a retry action.
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
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String errorMessage = AppStrings.fromKey(exception.userMessageKey);

    return Center(
      child: Padding(
        padding: AppSizes.paddingScreenH,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Soft tinted error icon in a circle
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: cs.error,
                size: 40,
              ),
            ),
            const SizedBox(height: AppSizes.p20),
            // Header
            Text(
              AppStrings.errorUnknown,
              style: AppTextStyles.headingSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.p8),
            // Error description
            Text(
              errorMessage,
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSizes.p24),
              AppButton(
                labelText: AppStrings.retry,
                onPressed: onRetry,
                variant: AppButtonVariant.secondary,
                shape: AppButtonShape.pill,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
