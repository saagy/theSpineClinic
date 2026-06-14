// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/network/router.dart';
import 'package:spine_clinic_app/features/admin/presentation/branch_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sharedPrefs = await SharedPreferences.getInstance();

  String url = const String.fromEnvironment('SUPABASE_URL');
  String key = const String.fromEnvironment('SUPABASE_ANON_KEY');
  print('MAIN: Initializing Supabase...');
  print('MAIN: SUPABASE_URL compile-time length: ${url.length}');

  if (url.isEmpty || key.isEmpty) {
    print('MAIN: Compile-time variables not found. Loading from .env asset...');
    try {
      final envContent = await rootBundle.loadString('.env');
      final lines = envContent.split('\n');
      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty || line.startsWith('#')) continue;
        final parts = line.split('=');
        if (parts.length >= 2) {
          final envKey = parts[0].trim();
          final envValue = parts.sublist(1).join('=').trim();
          if (envKey == 'SUPABASE_URL') {
            url = envValue;
          } else if (envKey == 'SUPABASE_ANON_KEY') {
            key = envValue;
          }
        }
      }
      print('MAIN: Loaded from .env asset successfully!');
      print('MAIN: SUPABASE_URL asset length: ${url.length}');
    } catch (e) {
      print('MAIN: Error loading .env asset: $e');
    }
  }

  await Supabase.initialize(
    url: url,
    anonKey: key,
  );
  print('MAIN: Supabase initialized successfully!');

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
      child: const SpineClinicApp(),
    ),
  );
}

/// Root application widget wired to the Riverpod-managed [GoRouter].
class SpineClinicApp extends ConsumerWidget {
  const SpineClinicApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      routerConfig: router,
    );
  }

  /// Builds the full Medics-inspired ThemeData with comprehensive
  /// component themes.
  ThemeData _buildTheme() {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: AppColors.textOnPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      onError: AppColors.textOnPrimary,
      surfaceContainerHighest: AppColors.primaryLight,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      useMaterial3: true,

      // ── Typography ──
      textTheme: TextTheme(
        displayLarge: AppTextStyles.headingLarge,
        displayMedium: AppTextStyles.headingMedium,
        titleLarge: AppTextStyles.headingSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.bodySecondary,
        labelLarge: AppTextStyles.button,
        labelMedium: AppTextStyles.bodyMedium,
        labelSmall: AppTextStyles.caption,
      ),

      // ── AppBar ──
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: AppTextStyles.headingSmall,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      // ── Cards ──
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppSizes.borderRadiusCard,
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // ── Elevated Buttons (Primary) ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.textMuted.withAlpha(80),
          disabledForegroundColor: AppColors.textOnPrimary,
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: AppSizes.borderRadiusPill,
          ),
          elevation: 0,
          shadowColor: AppColors.transparent,
          textStyle: AppTextStyles.button,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p24,
            vertical: AppSizes.p16,
          ),
        ),
      ),

      // ── Text Inputs ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p16,
          vertical: AppSizes.p14,
        ),
        border: OutlineInputBorder(
          borderRadius: AppSizes.borderRadiusInput,
          borderSide: const BorderSide(
            color: AppColors.border,
            width: AppSizes.borderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSizes.borderRadiusInput,
          borderSide: const BorderSide(
            color: AppColors.border,
            width: AppSizes.borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSizes.borderRadiusInput,
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: AppSizes.borderWidthFocused,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSizes.borderRadiusInput,
          borderSide: const BorderSide(
            color: AppColors.error,
            width: AppSizes.borderWidth,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSizes.borderRadiusInput,
          borderSide: const BorderSide(
            color: AppColors.error,
            width: AppSizes.borderWidthFocused,
          ),
        ),
        labelStyle: AppTextStyles.body,
        hintStyle: AppTextStyles.bodySecondary,
        errorStyle: AppTextStyles.caption.copyWith(
          color: AppColors.error,
        ),
        prefixIconColor: AppColors.primary,
        suffixIconColor: AppColors.textMuted,
      ),

      // ── Chips ──
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        labelStyle: AppTextStyles.captionMedium,
        secondaryLabelStyle: AppTextStyles.captionBold.copyWith(
          color: AppColors.textOnPrimary,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p12,
          vertical: AppSizes.p4,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppSizes.borderRadiusPill,
          side: const BorderSide(color: AppColors.border),
        ),
        side: const BorderSide(color: AppColors.border),
        checkmarkColor: AppColors.textOnPrimary,
      ),

      // ── Bottom Navigation ──
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: AppTextStyles.captionBold,
        unselectedLabelStyle: AppTextStyles.caption,
      ),

      // ── Dialogs ──
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppSizes.borderRadiusDialog,
        ),
        titleTextStyle: AppTextStyles.headingMedium,
      ),

      // ── Snackbar ──
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppTextStyles.body.copyWith(
          color: AppColors.textOnPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppSizes.borderRadiusCard,
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Dividers ──
      dividerTheme: DividerThemeData(
        color: AppColors.border,
        thickness: AppSizes.borderWidth,
        space: 0,
      ),

      // ── Tab Bar ──
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        dividerColor: AppColors.border,
        labelStyle: AppTextStyles.captionBold,
        unselectedLabelStyle: AppTextStyles.captionMedium,
      ),

      // ── Icon Theme ──
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: AppSizes.iconDefault,
      ),

      // ── List Tile ──
      listTileTheme: ListTileThemeData(
        contentPadding: AppSizes.paddingCell,
        titleTextStyle: AppTextStyles.bodyBold,
        subtitleTextStyle: AppTextStyles.bodySecondary,
        shape: RoundedRectangleBorder(
          borderRadius: AppSizes.borderRadiusCard,
        ),
      ),
    );
  }
}
