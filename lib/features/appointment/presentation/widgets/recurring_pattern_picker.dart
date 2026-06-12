library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/shared/widgets/app_text_field.dart';

/// Renders controls for picking recurrence weekdays and the total number of sessions.
class RecurringPatternPicker extends StatelessWidget {
  /// Creates a [RecurringPatternPicker] widget.
  const RecurringPatternPicker({
    super.key,
    required this.selectedWeekdays,
    required this.onWeekdaysChanged,
    required this.sessionsController,
    this.sessionsValidator,
    this.daysErrorText,
  });

  /// The currently selected weekday integers (1=Mon, 7=Sun).
  final Set<int> selectedWeekdays;

  /// Callback when the set of selected weekdays changes.
  final ValueChanged<Set<int>> onWeekdaysChanged;

  /// Controller for total recurring session count text input.
  final TextEditingController sessionsController;

  /// Optional validator for the session count field.
  final String? Function(String?)? sessionsValidator;

  /// Validation error text for the weekday selection.
  final String? daysErrorText;

  static const List<Map<String, dynamic>> _weekdaysList = [
    {'label': 'Sat', 'value': DateTime.saturday},
    {'label': 'Sun', 'value': DateTime.sunday},
    {'label': 'Mon', 'value': DateTime.monday},
    {'label': 'Tue', 'value': DateTime.tuesday},
    {'label': 'Wed', 'value': DateTime.wednesday},
    {'label': 'Thu', 'value': DateTime.thursday},
    {'label': 'Fri', 'value': DateTime.friday},
  ];

  void _toggleWeekday(int dayValue) {
    final Set<int> newSelection = Set<int>.from(selectedWeekdays);
    if (newSelection.contains(dayValue)) {
      newSelection.remove(dayValue);
    } else {
      newSelection.add(dayValue);
    }
    onWeekdaysChanged(newSelection);
  }

  @override
  Widget build(BuildContext context) {
    final bool hasDaysError = daysErrorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.selectDays,
          style: AppTextStyles.captionMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSizes.p8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _weekdaysList.map((day) {
            final String label = day['label'] as String;
            final int value = day['value'] as int;
            final bool isSelected = selectedWeekdays.contains(value);

            return InkWell(
              onTap: () => _toggleWeekday(value),
              borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r6)),
              child: Container(
                width: AppSizes.tappableMin,
                height: AppSizes.tappableMin,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r6)),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (hasDaysError ? AppColors.error : AppColors.border),
                    width: AppSizes.borderWidth,
                  ),
                ),
                child: Text(
                  label,
                  style: AppTextStyles.bodyBold.copyWith(
                    color: isSelected ? AppColors.surface : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (hasDaysError) ...[
          const SizedBox(height: AppSizes.p4),
          Text(
            daysErrorText!,
            style: AppTextStyles.caption.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: AppSizes.p16),
        AppTextField(
          controller: sessionsController,
          labelText: AppStrings.numberOfSessions,
          hintText: 'Enter number of sessions (max 24)',
          keyboardType: TextInputType.number,
          validator: sessionsValidator,
        ),
      ],
    );
  }
}
