import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';

enum AppButtonVariant { primary, secondary, danger, warning, success }

enum AppButtonShape { rounded, rounded12, pill }

BorderRadius appButtonBorderRadius(AppButtonShape shape) => switch (shape) {
  AppButtonShape.pill => AppSizes.borderRadiusPill,
  AppButtonShape.rounded12 => const BorderRadius.all(
    Radius.circular(AppSizes.r12),
  ),
  AppButtonShape.rounded => const BorderRadius.all(
    Radius.circular(AppSizes.r8),
  ),
};

class AppButtonColors {
  const AppButtonColors({
    required this.background,
    required this.foreground,
    required this.border,
    required this.shadows,
  });

  final Color background;
  final Color foreground;
  final BoxBorder? border;
  final List<BoxShadow> shadows;

  static AppButtonColors resolve(
    BuildContext context,
    AppButtonVariant variant,
    bool isDisabled,
  ) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ClinicColors clinic = ClinicColors.of(context);
    if (isDisabled) {
      return AppButtonColors(
        background: variant == AppButtonVariant.secondary
            ? cs.surface
            : clinic.textMuted.withAlpha(50),
        foreground: clinic.textMuted,
        border: variant == AppButtonVariant.secondary
            ? Border.all(color: cs.outline, width: AppSizes.borderWidth)
            : null,
        shadows: const [],
      );
    }

    return switch (variant) {
      AppButtonVariant.primary => AppButtonColors(
        background: cs.primary,
        foreground: cs.onPrimary,
        border: null,
        shadows: const [],
      ),
      AppButtonVariant.secondary => AppButtonColors(
        background: cs.surface,
        foreground: cs.onSurfaceVariant,
        border: Border.all(color: cs.outline, width: AppSizes.borderWidth),
        shadows: [clinic.cardShadow],
      ),
      AppButtonVariant.danger => AppButtonColors(
        background: cs.error,
        foreground: cs.onError,
        border: null,
        shadows: const [],
      ),
      AppButtonVariant.warning => AppButtonColors(
        background: clinic.warning,
        foreground: cs.onPrimary,
        border: null,
        shadows: const [],
      ),
      AppButtonVariant.success => AppButtonColors(
        background: clinic.success,
        foreground: cs.onPrimary,
        border: null,
        shadows: const [],
      ),
    };
  }
}
