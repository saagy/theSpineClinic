/// Custom loading overlay widget matching the Spine Clinic styling tokens.
///
/// Wraps a screen or content widget to display a full-screen, touch-blocking
/// modal loading indicator when asynchronous operations are in progress.
///
/// Rule 1 — keep files under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';

/// A full-screen blocking overlay spinner styled with Spine Clinic design tokens.
class LoadingOverlay extends StatelessWidget {
  /// Creates a [LoadingOverlay].
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  /// Whether the loading overlay spinner is visible.
  final bool isLoading;

  /// The widget content rendered beneath the overlay.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // If not loading, bypass Stack layout to eliminate layout/drawing overhead
    if (!isLoading) {
      return child;
    }

    return Stack(
      children: [
        child,
        // AbsorbPointer intercepts all gesture events, preventing interaction with child
        AbsorbPointer(
          absorbing: true,
          child: Container(
            color: Colors.black.withAlpha(102), // ~0.4 opacity background barrier
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
