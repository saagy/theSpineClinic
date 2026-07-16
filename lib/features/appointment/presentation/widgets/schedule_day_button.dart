import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

class ScheduleDayButton extends StatelessWidget {
  const ScheduleDayButton({
    super.key,
    required this.date,
    required this.appointmentCount,
    required this.selected,
    required this.today,
    required this.onPressed,
  });

  final DateTime date;
  final int appointmentCount;
  final bool selected;
  final bool today;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String fullDate = DateFormat.yMMMMEEEEd().format(date);
    final Color labelColor = selected || today
        ? colors.primary
        : colors.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: AppStrings.scheduleDaySemantics(
        fullDate,
        appointmentCount,
        selected: selected,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppSizes.borderRadiusCard,
          child: SizedBox(
            height: AppSizes.scheduleWeekHeight,
            child: ExcludeSemantics(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    DateFormat('EEE').format(date),
                    style: AppTextStyles.captionMedium.copyWith(
                      color: labelColor,
                    ),
                  ),
                  const SizedBox(height: AppSizes.p2),
                  Container(
                    width: AppSizes.scheduleDayMarkerSize,
                    height: AppSizes.scheduleDayMarkerSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? colors.primary
                          : colors.surface.withValues(alpha: 0),
                      shape: BoxShape.circle,
                      border: today && !selected
                          ? Border.all(
                              color: colors.primary,
                              width: AppSizes.borderWidthFocused,
                            )
                          : null,
                    ),
                    child: Text(
                      date.day.toString(),
                      style: AppTextStyles.bodyBold.copyWith(
                        color: selected ? colors.onPrimary : colors.onSurface,
                        fontFeatures: AppTextStyles.number.fontFeatures,
                      ),
                    ),
                  ),
                  Text(
                    appointmentCount == 0 ? '' : appointmentCount.toString(),
                    style: AppTextStyles.captionBold.copyWith(
                      color: selected ? colors.primary : labelColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
