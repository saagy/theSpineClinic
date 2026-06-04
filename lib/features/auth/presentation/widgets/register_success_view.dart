/// Post-registration success confirmation layout.
///
/// Displayed after a doctor successfully submits their registration
/// application. Shows a centered icon, confirmation message, and a
/// primary action button to navigate back to the login screen.
///
/// Rule 8 — no hardcoded colours or sizes.
/// Rule 7 — no hardcoded strings.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings_auth.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';

/// Full-screen confirmation view shown after successful doctor registration.
class RegisterSuccessView extends StatelessWidget {
  /// Creates a [RegisterSuccessView].
  const RegisterSuccessView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: AppSizes.paddingScreenH,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success icon
                const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 64,
                  color: AppColors.success,
                ),
                const SizedBox(height: AppSizes.p24),

                // Title
                Text(
                  AppStringsAuth.registrationSubmittedTitle,
                  style: AppTextStyles.headingLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.p12),

                // Description
                Text(
                  AppStringsAuth.registrationSubmittedMessage,
                  style: AppTextStyles.bodySecondary,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.p40),

                // Back to login button
                AppButton(
                  labelText: AppStringsAuth.backToLogin,
                  onPressed: () => context.go(AppRoutes.login),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
