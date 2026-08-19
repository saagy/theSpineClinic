// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:spine_clinic_app/core/constants/app_palette.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_theme.dart';
import 'package:spine_clinic_app/core/network/router.dart';
import 'package:spine_clinic_app/core/utils/local_settings_providers.dart';
import 'package:spine_clinic_app/core/utils/theme_mode_controller.dart';

const String _defaultSupabaseUrl = 'https://ujketpugttdqpcixrnga.supabase.co';
const String _defaultSupabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVqa2V0cHVndHRkcXBjaXhybmdhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA1MDczOTAsImV4cCI6MjA5NjA4MzM5MH0.TOUZwiAX6-GMygzXPriHKtYjd-FKGg0zOl8maI5cDa0';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final SharedPreferences sharedPrefs = await SharedPreferences.getInstance();
  String url = const String.fromEnvironment('SUPABASE_URL');
  String key = const String.fromEnvironment('SUPABASE_ANON_KEY');

  print('MAIN: Initializing Supabase...');

  if (url.isEmpty || key.isEmpty) {
    print('MAIN: Compile-time variables not found. Loading from .env asset...');
    try {
      final String envContent = await rootBundle.loadString('.env');
      final List<String> lines = envContent.split('\n');
      for (String line in lines) {
        line = line.trim();
        if (line.isEmpty || line.startsWith('#')) continue;
        final List<String> parts = line.split('=');
        if (parts.length < 2) continue;

        final String envKey = parts[0].trim();
        final String envValue = parts.sublist(1).join('=').trim();
        if (envKey == 'SUPABASE_URL' && envValue.isNotEmpty) {
          url = envValue;
        } else if (envKey == 'SUPABASE_ANON_KEY' && envValue.isNotEmpty) {
          key = envValue;
        }
      }
    } catch (e) {
      print('MAIN: Error loading .env asset: $e');
    }
  }

  if (url.isEmpty) url = _defaultSupabaseUrl;
  if (key.isEmpty) key = _defaultSupabaseAnonKey;

  await Supabase.initialize(url: url, anonKey: key);
  print('MAIN: Supabase initialized successfully!');

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(sharedPrefs)],
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
    final themeMode = ref.watch(themeModeControllerProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(clinicalBluePaletteLight),
      darkTheme: AppTheme.dark(clinicalBluePaletteDark),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is UserScrollNotification &&
                  notification.direction != ScrollDirection.idle) {
                FocusManager.instance.primaryFocus?.unfocus();
              }
              return false;
            },
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
