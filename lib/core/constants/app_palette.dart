import 'package:flutter/material.dart';

/// Concrete color values used to build app themes for the
/// single clinical-blue brand direction (light + dark).
class AppPalette {
  const AppPalette({
    required this.primary,
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

/// Light-mode clinical-blue palette.
const AppPalette clinicalBluePaletteLight = AppPalette(
  primary: Color(0xFF2563EB),
  primaryContainer: Color(0xFFDBEAFE),
  onPrimaryContainer: Color(0xFF1E3A8A),
  background: Color(0xFFF8FAFC),
  surface: Color(0xFFFFFFFF),
  surfaceContainer: Color(0xFFF1F5F9),
  textPrimary: Color(0xFF111827),
  textSecondary: Color(0xFF64748B),
  textMuted: Color(0xFF94A3B8),
  outline: Color(0xFFE2E8F0),
  outlineStrong: Color(0xFFCBD5E1),
);

/// Dark-mode clinical-blue palette.
const AppPalette clinicalBluePaletteDark = AppPalette(
  primary: Color(0xFF93C5FD),
  primaryContainer: Color(0xFF1E3A8A),
  onPrimaryContainer: Color(0xFFDBEAFE),
  background: Color(0xFF0F172A),
  surface: Color(0xFF111827),
  surfaceContainer: Color(0xFF1E293B),
  textPrimary: Color(0xFFF8FAFC),
  textSecondary: Color(0xFFCBD5E1),
  textMuted: Color(0xFF94A3B8),
  outline: Color(0xFF334155),
  outlineStrong: Color(0xFF475569),
);
