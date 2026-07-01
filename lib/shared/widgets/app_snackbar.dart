/// Custom snackbar utility matching the Stripe Dashboard styling design tokens.
///
/// Exposes a clean, namespaced helper function to display success, error, and
/// info alerts as floating snackbars with micro-shadows. Phone-only layout.
///
/// Rule 1 — keep files under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';

/// Available snackbar design variants.
enum AppSnackbarVariant {
  /// Green background, dark green text.
  success,

  /// Rose background, dark red text.
  error,

  /// Flat white background, Slate 900 text, and Slate 200 border line.
  info,
}

/// Central utility namespace for presenting custom styled application notifications.
abstract final class AppSnackbar {
  /// Displays a floating snackbar with appropriate variant colors and shadow profiles.
  ///
  /// Clears any active snackbars immediately before showing to prevent stacking delays.
  static void show(
    BuildContext context, {
    required String message,
    AppSnackbarVariant variant = AppSnackbarVariant.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ClinicColors clinic = ClinicColors.of(context);
    // Resolve variant styling parameters
    final Color backgroundColor;
    final Color textColor;
    final Border border;

    switch (variant) {
      case AppSnackbarVariant.success:
        backgroundColor = clinic.successContainer;
        textColor = clinic.success;
        border = Border.all(color: Colors.transparent, width: 0);
        break;
      case AppSnackbarVariant.error:
        backgroundColor = cs.errorContainer;
        textColor = cs.onErrorContainer;
        border = Border.all(color: Colors.transparent, width: 0);
        break;
      case AppSnackbarVariant.info:
        backgroundColor = cs.surface;
        textColor = cs.onSurface;
        border = Border.all(color: cs.outline, width: AppSizes.borderWidth);
        break;
    }

    final SnackBar snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.all(AppSizes.p16),
      padding: EdgeInsets.zero,
      duration: duration,
      content: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: AppSizes.borderRadiusCard,
          border: border,
          boxShadow: [clinic.cardShadow],
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p16,
          vertical: AppSizes.p12,
        ),
        child: Text(
          message,
          style: AppTextStyles.body.copyWith(
            color: textColor,
            fontWeight:
                FontWeight.w500, // Medium weight for high scanning readability
          ),
        ),
      ),
    );

    // Clear current snackbars immediately to avoid stacking delay on phone screens
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(snackBar);
  }
}
