/// Recurring pattern picker with compact weekday squares and session count.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/shared/widgets/app_text_field.dart';

class RecurringPatternPicker extends StatelessWidget {
  const RecurringPatternPicker({
    super.key,
    required this.selectedWeekdays,
    required this.onWeekdaysChanged,
    required this.sessionsController,
    this.sessionsValidator,
    this.daysErrorText,
  });

  final Set<int> selectedWeekdays;
  final ValueChanged<Set<int>> onWeekdaysChanged;
  final TextEditingController sessionsController;
  final String? Function(String?)? sessionsValidator;
  final String? daysErrorText;

  static const List<({String label, int value})> _days = [
    (label: 'Sat', value: DateTime.saturday),
    (label: 'Sun', value: DateTime.sunday),
    (label: 'Mon', value: DateTime.monday),
    (label: 'Tue', value: DateTime.tuesday),
    (label: 'Wed', value: DateTime.wednesday),
    (label: 'Thu', value: DateTime.thursday),
    (label: 'Fri', value: DateTime.friday),
  ];

  @override
  Widget build(BuildContext context) {
    final bool err = daysErrorText != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Select Days', style: AppTextStyles.captionMedium.copyWith(color: AppColors.textSecondary)),
      const SizedBox(height: AppSizes.p8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _days.map((d) {
          final bool active = selectedWeekdays.contains(d.value);
          return InkWell(
            onTap: () {
              final set = Set<int>.from(selectedWeekdays);
              active ? set.remove(d.value) : set.add(d.value);
              onWeekdaysChanged(set);
            },
            borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r6)),
            child: Container(
              width: AppSizes.tappableMin,
              height: AppSizes.tappableMin,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.surface,
                borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r6)),
                border: Border.all(
                  color: active ? AppColors.primary : (err ? AppColors.error : AppColors.border),
                  width: AppSizes.borderWidth,
                ),
              ),
              child: Text(d.label,
                  style: AppTextStyles.bodyBold.copyWith(
                      color: active ? AppColors.surface : AppColors.textPrimary)),
            ),
          );
        }).toList(),
      ),
      if (err) ...[const SizedBox(height: AppSizes.p4), Text(daysErrorText!, style: AppTextStyles.caption.copyWith(color: AppColors.error))],
      const SizedBox(height: AppSizes.p16),
      AppTextField(
        controller: sessionsController, labelText: 'Number of Sessions',
        hintText: 'Max 24', keyboardType: TextInputType.number, validator: sessionsValidator,
      ),
    ]);
  }
}
