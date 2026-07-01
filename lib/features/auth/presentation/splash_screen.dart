import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';

/// Full-screen loading indicator shown during auth state resolution.
class SplashScreen extends StatelessWidget {
  /// Creates a [SplashScreen].
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modern icon badge matching Web loader
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withOpacity(0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.spa_rounded,
                    color: cs.onPrimary,
                    size: 44,
                  ),
                ),
                const SizedBox(height: AppSizes.p24),
                // Typographic clinic brand mark
                Text(
                  'THE SPINE CLINIC',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: AppSizes.p6),
                Text(
                  'Clinical Excellence Center',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .fade(duration: 1200.ms, curve: Curves.easeInOut)
            .scaleXY(begin: 0.98, end: 1.02, duration: 1200.ms, curve: Curves.easeInOut),
          ),
          Positioned(
            bottom: 64,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 140,
                child: LinearProgressIndicator(
                  color: cs.primary,
                  backgroundColor: cs.primaryContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(100),
                  minHeight: 3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
