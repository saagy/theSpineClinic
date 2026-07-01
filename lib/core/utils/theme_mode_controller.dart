import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/utils/local_settings_providers.dart';
import 'package:spine_clinic_app/core/utils/local_settings_service.dart';
import 'package:spine_clinic_app/shared/widgets/sort_options_sheet.dart';

/// Holds the user's preferred [ThemeMode] for the app. Defaults to
/// [ThemeMode.light] and persists every change via [LocalSettingsService].
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final LocalSettingsService service = ref.watch(
      localSettingsServiceProvider,
    );
    return service.getThemeMode();
  }

  /// Updates and persists the user-selected [ThemeMode].
  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final LocalSettingsService service = ref.read(
      localSettingsServiceProvider,
    );
    await service.setThemeMode(mode);
  }

  /// Opens the [SortOptionsSheet] picker and persists any selection.
  static Future<void> pickFromSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final ThemeMode? next = await SortOptionsSheet.show<ThemeMode>(
      context: context,
      title: AppStrings.theme,
      selected: ref.read(themeModeControllerProvider),
      options: const [
        SortOption<ThemeMode>(
          value: ThemeMode.light,
          label: AppStrings.themeModeLight,
        ),
        SortOption<ThemeMode>(
          value: ThemeMode.dark,
          label: AppStrings.themeModeDark,
        ),
        SortOption<ThemeMode>(
          value: ThemeMode.system,
          label: AppStrings.themeModeSystem,
        ),
      ],
    );
    if (next != null) {
      await ref.read(themeModeControllerProvider.notifier).setMode(next);
    }
  }
}

/// Provider exposing the active [ThemeMode].
final themeModeControllerProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(
      ThemeModeController.new,
    );

/// Renders the user-facing label for a [ThemeMode] value.
String themeModeLabel(ThemeMode mode) => switch (mode) {
  ThemeMode.light => AppStrings.themeModeLight,
  ThemeMode.dark => AppStrings.themeModeDark,
  ThemeMode.system => AppStrings.themeModeSystem,
};
