import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/utils/local_settings_providers.dart';
import 'package:spine_clinic_app/core/utils/local_settings_service.dart';
import 'package:spine_clinic_app/shared/widgets/sort_options_sheet.dart';

/// Holds the user's preferred schedule card density (compact vs standard).
/// Defaults to standard (`false`) and persists changes via [LocalSettingsService].
class ScheduleCompactController extends Notifier<bool> {
  @override
  bool build() {
    try {
      final LocalSettingsService service = ref.watch(
        localSettingsServiceProvider,
      );
      return service.isScheduleCompact();
    } catch (_) {
      return false;
    }
  }

  /// Toggles between standard and compact view modes.
  Future<void> toggle() async {
    await setCompact(!state);
  }

  /// Updates and persists the schedule density mode (`true` = compact, `false` = standard).
  Future<void> setCompact(bool isCompact) async {
    state = isCompact;
    try {
      final LocalSettingsService service = ref.read(
        localSettingsServiceProvider,
      );
      await service.setScheduleCompact(isCompact);
    } catch (_) {}
  }

  /// Opens the [SortOptionsSheet] picker for schedule density.
  static Future<void> pickFromSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final bool? next = await SortOptionsSheet.show<bool>(
      context: context,
      title: AppStrings.scheduleDensity,
      selected: ref.read(scheduleCompactControllerProvider),
      options: const [
        SortOption<bool>(
          value: false,
          label: AppStrings.scheduleDensityStandard,
        ),
        SortOption<bool>(
          value: true,
          label: AppStrings.scheduleDensityCompact,
        ),
      ],
    );
    if (next != null) {
      await ref
          .read(scheduleCompactControllerProvider.notifier)
          .setCompact(next);
    }
  }
}

/// Provider exposing whether schedule lists should render in compact mode.
final scheduleCompactControllerProvider =
    NotifierProvider<ScheduleCompactController, bool>(
      ScheduleCompactController.new,
    );

/// User-facing label for schedule density.
String scheduleDensityLabel(bool isCompact) => isCompact
    ? AppStrings.scheduleDensityCompact
    : AppStrings.scheduleDensityStandard;
