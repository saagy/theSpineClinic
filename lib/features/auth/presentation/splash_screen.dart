import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:spine_clinic_app/shared/widgets/ambient_glow_background.dart';
import 'package:spine_clinic_app/shared/widgets/clinic_brand_mark.dart';

/// Full-screen ambient loading splash shown during auth state resolution.
class SplashScreen extends StatelessWidget {
  /// Creates a [SplashScreen].
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: AmbientGlowBackground(
        child: Stack(
          children: [
            Center(
              child: const ClinicBrandMark(
                width: 250,
                showSubtitle: true,
              )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .fade(duration: 1200.ms, curve: Curves.easeInOut)
                  .scaleXY(
                    begin: 0.97,
                    end: 1.02,
                    duration: 1200.ms,
                    curve: Curves.easeInOut,
                  ),
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
                    backgroundColor: cs.primaryContainer.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(100),
                    minHeight: 3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
