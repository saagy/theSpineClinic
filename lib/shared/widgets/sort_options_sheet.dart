/// A generic sort-options picker displayed inside an [AppBottomSheet].
///
/// Renders a list of [SortOption] items with a checkmark next to the
/// currently selected option. Tapping an option selects it and closes
/// the sheet.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';

/// A single sort option with a typed value and display label.
class SortOption<T> {
  /// Creates a [SortOption].
  const SortOption({
    required this.value,
    required this.label,
    this.buttonLabel,
  });

  /// The typed value identifying this option.
  final T value;

  /// Full label shown in the sort options sheet.
  final String label;

  /// Shorter label for the sort button text. Falls back to [label] if null.
  final String? buttonLabel;
}

/// A widget that renders sort options inside a bottom sheet.
class SortOptionsSheet<T> extends StatelessWidget {
  /// Creates a [SortOptionsSheet].
  const SortOptionsSheet({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  /// The list of available sort options.
  final List<SortOption<T>> options;

  /// The currently selected option value.
  final T selected;

  /// Called when the user selects an option.
  final ValueChanged<T> onSelected;

  /// Shows a sort options bottom sheet and returns the selected option.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<SortOption<T>> options,
    required T selected,
  }) {
    return AppBottomSheet.show<T>(
      context: context,
      title: title,
      builder: (context, scrollController) => SortOptionsSheet<T>(
        options: options,
        selected: selected,
        onSelected: (T value) => Navigator.of(context).pop(value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return ListView.builder(
      controller: null, // scrollController handled by AppBottomSheet
      shrinkWrap: true,
      itemCount: options.length,
      itemBuilder: (context, index) {
        final SortOption<T> option = options[index];
        final bool isSelected = option.value == selected;
        return ListTile(
          title: Text(
            option.label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isSelected ? cs.primary : cs.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          trailing: isSelected
              ? Icon(Icons.check_rounded, color: cs.primary)
              : null,
          onTap: () => onSelected(option.value),
        );
      },
    );
  }
}
