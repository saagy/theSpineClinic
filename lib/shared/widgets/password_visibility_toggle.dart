/// Reusable show/hide password eye-icon toggle.
///
/// Renders an [InkWell] with the Material outlined visibility icon that
/// flips between `visibility_outlined` (text visible) and
/// `visibility_off_outlined` (text obscured). Designed to be dropped into
/// any `suffixIcon` slot.
///
/// Rule 17 — shared widget, reused by every password field in the app.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';

/// Eye-icon toggle that signals whether a password field should be obscured.
class PasswordVisibilityToggle extends StatelessWidget {
  /// Creates a [PasswordVisibilityToggle].
  const PasswordVisibilityToggle({
    super.key,
    required this.isObscured,
    required this.onToggle,
  });

  /// Whether the linked field is currently obscuring its text.
  final bool isObscured;

  /// Called when the user taps the eye icon.
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(AppSizes.iconDefault),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p4),
        child: Icon(
          isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: AppSizes.iconDefault,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
