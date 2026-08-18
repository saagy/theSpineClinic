import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';

/// A modern frosted-glass card with backdrop blur, specular border, and elevation shadow.
///
/// Adapts seamlessly to Light and Dark themes according to the Medics UI Kit standards.
class FrostedGlassCard extends StatelessWidget {
  /// Creates a [FrostedGlassCard].
  const FrostedGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSizes.p24),
    this.borderRadius = AppSizes.r24,
    this.blurSigma = 18.0,
  });

  /// The widget inside the card.
  final Widget child;

  /// Internal padding for the card content.
  final EdgeInsetsGeometry padding;

  /// Corner radius of the card.
  final double borderRadius;

  /// The Gaussian blur sigma for the backdrop filter.
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    final Color topFill = isDark
        ? cs.surface.withValues(alpha: 0.72)
        : Colors.white.withValues(alpha: 0.82);

    final Color bottomFill = isDark
        ? cs.surfaceContainer.withValues(alpha: 0.52)
        : Colors.white.withValues(alpha: 0.60);

    final Color borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.85);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.40)
                : cs.primary.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 10),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.20)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [topFill, bottomFill],
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor,
                width: 1.2,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
