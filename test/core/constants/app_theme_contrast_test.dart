import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_palette.dart';
import 'package:spine_clinic_app/core/constants/app_theme.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';

double contrast(Color a, Color b) {
  final light = a.computeLuminance() > b.computeLuminance() ? a : b;
  final dark = identical(light, a) ? b : a;
  return (light.computeLuminance() + 0.05) / (dark.computeLuminance() + 0.05);
}

void main() {
  test('dark theme keeps surface hierarchy and readable color pairs', () {
    final theme = AppTheme.dark(clinicalBluePaletteDark);
    final cs = theme.colorScheme;
    final clinic = theme.extension<ClinicColors>()!;

    expect(
      cs.surface.computeLuminance(),
      greaterThan(theme.scaffoldBackgroundColor.computeLuminance()),
    );
    expect(
      cs.surfaceContainer.computeLuminance(),
      greaterThan(cs.surface.computeLuminance()),
    );
    expect(contrast(cs.onPrimary, cs.primary), greaterThanOrEqualTo(4.5));
    expect(contrast(cs.onSurface, cs.surface), greaterThanOrEqualTo(4.5));
    expect(
      contrast(cs.onSurfaceVariant, cs.surface),
      greaterThanOrEqualTo(4.5),
    );
    expect(contrast(clinic.textMuted, cs.surface), greaterThanOrEqualTo(4.5));
    expect(contrast(cs.primary, cs.surface), greaterThanOrEqualTo(4.5));
    expect(contrast(cs.outline, cs.surface), greaterThanOrEqualTo(3));
    expect(
      contrast(clinic.success, clinic.successContainer),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrast(clinic.warning, clinic.warningContainer),
      greaterThanOrEqualTo(4.5),
    );
    expect(contrast(cs.error, cs.errorContainer), greaterThanOrEqualTo(4.5));
  });
}
