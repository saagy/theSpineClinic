import 'package:flutter/material.dart';

/// A static, refined clinical ambient background.
///
/// Features subtle, non-distracting atmospheric gradient washes that provide
/// depth for frosted glass cards in both light and dark themes without continuous
/// animation overhead or battery consumption.
class AmbientGlowBackground extends StatelessWidget {
  /// Creates an [AmbientGlowBackground].
  const AmbientGlowBackground({
    super.key,
    required this.child,
  });

  /// The foreground content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);

    // Subtle atmospheric accents for medical aesthetic
    final Color topGlow = isDark
        ? cs.primary.withValues(alpha: 0.14)
        : cs.primary.withValues(alpha: 0.07);

    final Color bottomGlow = isDark
        ? const Color(0xFF0284C7).withValues(alpha: 0.10)
        : const Color(0xFF0284C7).withValues(alpha: 0.05);

    return Stack(
      children: [
        // Base canvas
        Container(
          width: double.infinity,
          height: double.infinity,
          color: theme.scaffoldBackgroundColor,
        ),

        // Top-right static atmospheric glow
        Positioned(
          top: -size.width * 0.25,
          right: -size.width * 0.20,
          child: IgnorePointer(
            child: Container(
              width: size.width * 0.95,
              height: size.width * 0.95,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    topGlow,
                    topGlow.withValues(alpha: topGlow.a * 0.4),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
        ),

        // Bottom-left static atmospheric glow
        Positioned(
          bottom: -size.width * 0.25,
          left: -size.width * 0.20,
          child: IgnorePointer(
            child: Container(
              width: size.width * 0.90,
              height: size.width * 0.90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    bottomGlow,
                    bottomGlow.withValues(alpha: bottomGlow.a * 0.35),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
        ),

        // Soft linear overlay for smooth vignette and contrast
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    theme.scaffoldBackgroundColor.withValues(
                      alpha: isDark ? 0.35 : 0.25,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Foreground content
        child,
      ],
    );
  }
}

