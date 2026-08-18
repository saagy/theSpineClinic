import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Renders a living, dynamic ambient gradient background with smoothly drifting & pulsing glowing orbs.
class AmbientGlowBackground extends StatefulWidget {
  /// Creates an [AmbientGlowBackground].
  const AmbientGlowBackground({
    super.key,
    required this.child,
  });

  /// The foreground content.
  final Widget child;

  @override
  State<AmbientGlowBackground> createState() => _AmbientGlowBackgroundState();
}

class _AmbientGlowBackgroundState extends State<AmbientGlowBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);

    // Vibrant, alive clinical glow tones
    final Color blueOrb = isDark
        ? const Color(0xFF2563EB).withValues(alpha: 0.48)
        : const Color(0xFF3B82F6).withValues(alpha: 0.28);
    final Color tealOrb = isDark
        ? const Color(0xFF0D9488).withValues(alpha: 0.42)
        : const Color(0xFF14B8A6).withValues(alpha: 0.26);
    final Color skyOrb = isDark
        ? const Color(0xFF0284C7).withValues(alpha: 0.38)
        : const Color(0xFF38BDF8).withValues(alpha: 0.25);
    final Color indigoOrb = isDark
        ? const Color(0xFF4F46E5).withValues(alpha: 0.35)
        : const Color(0xFF818CF8).withValues(alpha: 0.22);

    return Stack(
      children: [
        // Base canvas
        Container(
          width: double.infinity,
          height: double.infinity,
          color: theme.scaffoldBackgroundColor,
        ),

        // Animated Ambient Orbs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value * 2 * math.pi;
            final double s1 = 0.90 + 0.18 * math.sin(t);
            final double s2 = 0.92 + 0.16 * math.cos(t * 0.9);
            final double s3 = 0.88 + 0.20 * math.sin(t * 1.1);

            final double dx1 = math.sin(t) * 70;
            final double dy1 = math.cos(t) * 60;
            final double dx2 = math.cos(t * 0.8) * 80;
            final double dy2 = math.sin(t * 0.8) * 70;
            final double dx3 = math.sin(t * 1.2) * 65;
            final double dy3 = math.cos(t * 1.2) * 75;

            return Stack(
              children: [
                // Top-Left Primary Blue Orb
                Positioned(
                  top: -60 + dy1,
                  left: -50 + dx1,
                  child: Transform.scale(
                    scale: s1,
                    child: _GlowingOrb(
                      size: size.width * 0.75,
                      color: blueOrb,
                    ),
                  ),
                ),

                // Bottom-Right Clinical Teal Orb
                Positioned(
                  bottom: -70 + dy2,
                  right: -60 + dx2,
                  child: Transform.scale(
                    scale: s2,
                    child: _GlowingOrb(
                      size: size.width * 0.80,
                      color: tealOrb,
                    ),
                  ),
                ),

                // Center-Left Floating Sky Orb
                Positioned(
                  top: size.height * 0.40 + dy3,
                  left: -80 + dx3,
                  child: Transform.scale(
                    scale: s3,
                    child: _GlowingOrb(
                      size: size.width * 0.65,
                      color: skyOrb,
                    ),
                  ),
                ),

                // Top-Right Indigo Orb
                Positioned(
                  top: size.height * 0.15 - dy2 * 0.8,
                  right: -70 - dx2 * 0.8,
                  child: Transform.scale(
                    scale: s1,
                    child: _GlowingOrb(
                      size: size.width * 0.60,
                      color: indigoOrb,
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        // Foreground content
        widget.child,
      ],
    );
  }
}

class _GlowingOrb extends StatelessWidget {
  const _GlowingOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: color.a * 0.45),
              color.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
      ),
    );
  }
}
