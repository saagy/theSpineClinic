import 'package:flutter/material.dart';

/// Concrete color values used to build app themes for the
/// single clinical-blue brand direction (light + dark).
class AppPalette {
  const AppPalette({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.background,
    required this.surface,
    required this.surfaceContainer,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.outline,
    required this.outlineStrong,
  });

  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color background;
  final Color surface;
  final Color surfaceContainer;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color outline;
  final Color outlineStrong;
}

/// Light-mode clinical-blue palette with brand #2B4D73 identity.
const AppPalette clinicalBluePaletteLight = AppPalette(
  primary: Color(0xFF2B4D73),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFE2EAF1),
  onPrimaryContainer: Color(0xFF162A40),
  background: Color(0xFFF8FAFC),
  surface: Color(0xFFFFFFFF),
  surfaceContainer: Color(0xFFF1F5F9),
  textPrimary: Color(0xFF111827),
  textSecondary: Color(0xFF64748B),
  textMuted: Color(0xFF94A3B8),
  outline: Color(0xFFE2E8F0),
  outlineStrong: Color(0xFFCBD5E1),
);

/// Dark-mode charcoal surfaces with a restrained clinical-blue accent.
const AppPalette clinicalBluePaletteDark = AppPalette(
  primary: Color(0xFFA9C8E8),
  onPrimary: Color(0xFF10263B),
  primaryContainer: Color(0xFF283F56),
  onPrimaryContainer: Color(0xFFE1EFFD),
  background: Color(0xFF12161B),
  surface: Color(0xFF1C2229),
  surfaceContainer: Color(0xFF252D36),
  textPrimary: Color(0xFFF2F5F8),
  textSecondary: Color(0xFFB4BFCC),
  textMuted: Color(0xFFA3AEBC),
  outline: Color(0xFF3A4652),
  outlineStrong: Color(0xFF6D7B8C),
);
