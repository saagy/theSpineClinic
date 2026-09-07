import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// Modern 2026 SaaS day button for the schedule week strip.
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
          borderRadius: BorderRadius.circular(AppSizes.r12),
          child: SizedBox(
            height: AppSizes.scheduleWeekHeight,
            child: ExcludeSemantics(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    DateFormat('EEE').format(date).toUpperCase(),
                    style: AppTextStyles.captionBold.copyWith(
                      color: labelColor,
                      fontSize: 10.5,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppSizes.p4),
                  Container(
                    width: AppSizes.scheduleDayMarkerSize,
                    height: AppSizes.scheduleDayMarkerSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? colors.primary
                          : (today
                              ? colors.primary.withAlpha(24)
                              : Colors.transparent),
                      borderRadius: BorderRadius.circular(AppSizes.r8),
                      border: today && !selected
                          ? Border.all(
                              color: colors.primary.withAlpha(180),
                              width: AppSizes.borderWidthFocused,
                            )
                          : null,
                    ),
                    child: Text(
                      date.day.toString(),
                      style: AppTextStyles.bodyBold.copyWith(
                        color: selected
                            ? colors.onPrimary
                            : (today ? colors.primary : colors.onSurface),
                        fontFeatures: const [FontFeature.tabularFigures()],
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  SizedBox(
                    height: 14.0,
                    child: Text(
                      appointmentCount == 0 ? '' : appointmentCount.toString(),
                      style: AppTextStyles.captionBold.copyWith(
                        color: selected ? colors.primary : colors.onSurfaceVariant,
                        fontSize: 10.5,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
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
