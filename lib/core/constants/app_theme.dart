import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_palette.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_theme_components.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';

/// Builds app-wide Material themes from a clinical-blue palette.
abstract final class AppTheme {
  static ThemeData light(AppPalette palette) {
    return _build(palette, Brightness.light);
  }

  static ThemeData dark(AppPalette palette) {
    return _build(palette, Brightness.dark);
  }

  static ThemeData _build(AppPalette palette, Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final ClinicColors clinic = ClinicColors.fromPalette(
      palette,
      isDark: isDark,
    );
    final Color error = isDark
        ? const Color(0xFFFB7185)
        : const Color(0xFFE11D48);
    final ColorScheme cs =
        ColorScheme.fromSeed(
          seedColor: palette.primary,
          brightness: brightness,
        ).copyWith(
          primary: palette.primary,
          onPrimary: Colors.white,
          primaryContainer: palette.primaryContainer,
          onPrimaryContainer: palette.onPrimaryContainer,
          surface: palette.surface,
          onSurface: palette.textPrimary,
          surfaceContainer: palette.surfaceContainer,
          surfaceContainerHighest: palette.surfaceContainer,
          onSurfaceVariant: palette.textSecondary,
          outline: palette.outline,
          error: error,
          onError: Colors.white,
          shadow: Colors.black,
        );

    return ThemeData(
      colorScheme: cs,
      scaffoldBackgroundColor: palette.background,
      useMaterial3: true,
      extensions: [clinic],
      textTheme: AppThemeComponents.textTheme(palette),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.surface,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: AppTextStyles.headingSmall.copyWith(
          color: palette.textPrimary,
        ),
        iconTheme: IconThemeData(color: palette.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: AppSizes.borderRadiusCard),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          disabledBackgroundColor: clinic.textMuted.withAlpha(80),
          disabledForegroundColor: cs.onPrimary,
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: AppSizes.borderRadiusPill,
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: AppTextStyles.button,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p24,
            vertical: AppSizes.p16,
          ),
        ),
      ),
      inputDecorationTheme: AppThemeComponents.inputTheme(cs, clinic, palette),
      chipTheme: ChipThemeData(
        backgroundColor: cs.surface,
        selectedColor: cs.primary,
        labelStyle: AppTextStyles.captionMedium.copyWith(
          color: cs.onSurfaceVariant,
        ),
        secondaryLabelStyle: AppTextStyles.captionBold.copyWith(
          color: cs.onPrimary,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p12,
          vertical: AppSizes.p4,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppSizes.borderRadiusPill,
          side: BorderSide(color: cs.outline),
        ),
        side: BorderSide(color: cs.outline),
        checkmarkColor: cs.onPrimary,
      ),
      navigationBarTheme: AppThemeComponents.navigationBarTheme(cs),
      navigationRailTheme: AppThemeComponents.navigationRailTheme(cs),
      dialogTheme: DialogThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppSizes.borderRadiusDialog,
        ),
        titleTextStyle: AppTextStyles.headingMedium.copyWith(
          color: cs.onSurface,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cs.onSurface,
        contentTextStyle: AppTextStyles.body.copyWith(color: cs.surface),
        shape: RoundedRectangleBorder(borderRadius: AppSizes.borderRadiusCard),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: DividerThemeData(
        color: cs.outline,
        thickness: AppSizes.borderWidth,
        space: 0,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: cs.primary,
        unselectedLabelColor: cs.onSurfaceVariant,
        indicatorColor: cs.primary,
        dividerColor: cs.outline,
        labelStyle: AppTextStyles.captionBold,
        unselectedLabelStyle: AppTextStyles.captionMedium,
      ),
      iconTheme: IconThemeData(
        color: cs.onSurfaceVariant,
        size: AppSizes.iconDefault,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: AppSizes.paddingCell,
        titleTextStyle: AppTextStyles.bodyBold.copyWith(color: cs.onSurface),
        subtitleTextStyle: AppTextStyles.bodySecondary.copyWith(
          color: cs.onSurfaceVariant,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppSizes.borderRadiusCard),
      ),
    );
  }
}
