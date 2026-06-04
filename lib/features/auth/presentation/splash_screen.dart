/// Boot-time splash overlay displayed while the router resolves
/// the initial authentication state.
///
/// Contains no business logic — purely a visual placeholder using
/// design tokens from [AppColors].
///
/// Rule 8 — no hardcoded colours or sizes.
library;

import 'package:flutter/material.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';

/// Full-screen loading indicator shown during auth state resolution.
class SplashScreen extends StatelessWidget {
  /// Creates a [SplashScreen].
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}
