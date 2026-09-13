/// Responsive weekday selection: all seven fit, or wrap without shrinking targets.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
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
  static const _dayValues = [
    DateTime.saturday,
    DateTime.sunday,
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final minimum = AppSizes.tappableMin * (scale < 1 ? 1 : scale);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.selectDays,
          style: AppTextStyles.captionMedium.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: AppSizes.p8),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = AppSizes.p6;
            final columns = constraints.maxWidth >= minimum * 7 + gap * 6
                ? 7
                : ((constraints.maxWidth + gap) / (minimum + gap)).floor().clamp(1, 4);
            final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (int index = 0; index < _dayValues.length; index++)
                  SizedBox(
                    width: width,
                    child: Semantics(
                      selected: selectedWeekdays.contains(_dayValues[index]),
                      child: OutlinedButton(
                        onPressed: () {
                          final days = Set<int>.from(selectedWeekdays);
                          days.contains(_dayValues[index])
                              ? days.remove(_dayValues[index])
                              : days.add(_dayValues[index]);
                          onWeekdaysChanged(days);
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size(AppSizes.tappableMin, minimum),
                          visualDensity: VisualDensity.standard,
                          padding: const EdgeInsets.all(AppSizes.p4),
                          backgroundColor: selectedWeekdays.contains(_dayValues[index])
                              ? cs.primary
                              : cs.surface,
                          foregroundColor: selectedWeekdays.contains(_dayValues[index])
                              ? cs.onPrimary
                              : cs.onSurface,
                          side: BorderSide(
                            color: selectedWeekdays.contains(_dayValues[index])
                                ? cs.primary
                                : daysErrorText != null
                                ? cs.error
                                : cs.outlineVariant,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.r6),
                          ),
                          textStyle: AppTextStyles.bodyBold,
                        ),
                        child: Text(
                          AppStrings.weekdayShortLabels[index],
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        if (daysErrorText != null) ...[
          const SizedBox(height: AppSizes.p4),
          Text(daysErrorText!, style: AppTextStyles.caption.copyWith(color: cs.error)),
        ],
        const SizedBox(height: AppSizes.p16),
        AppTextField(
          controller: sessionsController,
          labelText: AppStrings.numberOfSessions,
          hintText: AppStrings.recurringSessionsHint,
          keyboardType: TextInputType.number,
          validator: sessionsValidator,
        ),
      ],
    );
  }
}
