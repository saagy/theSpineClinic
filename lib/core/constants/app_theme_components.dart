import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_palette.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';

/// Component theme helpers used by [AppTheme].
abstract final class AppThemeComponents {
  static TextTheme textTheme(AppPalette palette) {
    return TextTheme(
      displayLarge: AppTextStyles.headingLarge.copyWith(
        color: palette.textPrimary,
      ),
      displayMedium: AppTextStyles.headingMedium.copyWith(
        color: palette.textPrimary,
      ),
      headlineSmall: AppTextStyles.headingLarge.copyWith(
        color: palette.textPrimary,
      ),
      titleLarge: AppTextStyles.headingSmall.copyWith(
        color: palette.textPrimary,
      ),
      titleMedium: AppTextStyles.headingSmall.copyWith(
        color: palette.textPrimary,
      ),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: palette.textSecondary),
      bodyMedium: AppTextStyles.body.copyWith(color: palette.textPrimary),
      bodySmall: AppTextStyles.bodySecondary.copyWith(
        color: palette.textSecondary,
      ),
      labelLarge: AppTextStyles.button.copyWith(color: Colors.white),
      labelMedium: AppTextStyles.bodyMedium.copyWith(
        color: palette.textPrimary,
      ),
      labelSmall: AppTextStyles.caption.copyWith(color: palette.textMuted),
    );
  }

  static InputDecorationTheme inputTheme(
    ColorScheme cs,
    ClinicColors clinic,
    AppPalette palette,
  ) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: AppSizes.borderRadiusInput,
      borderSide: BorderSide(color: color, width: width),
    );
    return InputDecorationTheme(
      filled: true,
      fillColor: cs.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p16,
        vertical: AppSizes.p14,
      ),
      border: border(cs.outline, AppSizes.borderWidth),
      enabledBorder: border(cs.outline, AppSizes.borderWidth),
      focusedBorder: border(cs.primary, AppSizes.borderWidthFocused),
      errorBorder: border(cs.error, AppSizes.borderWidth),
      focusedErrorBorder: border(cs.error, AppSizes.borderWidthFocused),
      labelStyle: AppTextStyles.body.copyWith(color: cs.onSurface),
      hintStyle: AppTextStyles.bodySecondary.copyWith(color: clinic.textMuted),
      errorStyle: AppTextStyles.caption.copyWith(color: cs.error),
      prefixIconColor: cs.primary,
      suffixIconColor: palette.textMuted,
    );
  }

  static NavigationBarThemeData navigationBarTheme(ColorScheme cs) {
    return NavigationBarThemeData(
      backgroundColor: cs.surfaceContainer,
      indicatorColor: cs.primaryContainer,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: AppSizes.bottomNavHeight,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppTextStyles.captionBold.copyWith(
            color: cs.onPrimaryContainer,
          );
        }
        return AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(
            color: cs.onPrimaryContainer,
            size: AppSizes.iconDefault,
          );
        }
        return IconThemeData(
          color: cs.onSurfaceVariant,
          size: AppSizes.iconDefault,
        );
      }),
    );
  }

  static NavigationRailThemeData navigationRailTheme(ColorScheme cs) {
    return NavigationRailThemeData(
      backgroundColor: cs.surface,
      indicatorColor: cs.primaryContainer,
      selectedIconTheme: IconThemeData(
        color: cs.onPrimaryContainer,
        size: AppSizes.iconDefault,
      ),
      unselectedIconTheme: IconThemeData(
        color: cs.onSurfaceVariant,
        size: AppSizes.iconDefault,
      ),
      selectedLabelTextStyle: AppTextStyles.captionBold.copyWith(
        color: cs.onPrimaryContainer,
      ),
      unselectedLabelTextStyle: AppTextStyles.caption.copyWith(
        color: cs.onSurfaceVariant,
      ),
      elevation: 0,
      minWidth: AppSizes.navRailWidth,
    );
  }
}
