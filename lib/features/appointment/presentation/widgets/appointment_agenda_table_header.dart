import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// Contextual column header for desktop appointment agenda layouts (>= 650px).
///
/// Automatically hides on mobile viewports (< 650px).
/// The Doctor column is contextual and can be omitted via [showDoctor].
class AppointmentAgendaTableHeader extends StatelessWidget {
  const AppointmentAgendaTableHeader({
    super.key,
    this.showDoctor = true,
  });

  final bool showDoctor;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    if (width < 650.0) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final TextStyle labelStyle = AppTextStyles.captionBold.copyWith(
      color: cs.onSurfaceVariant,
      letterSpacing: 0.8,
      fontSize: 11.0,
    );

    return Container(
      height: 38.0,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(80),
        border: Border(
          top: BorderSide(
            color: cs.outlineVariant.withAlpha(80),
            width: AppSizes.borderWidth,
          ),
          bottom: BorderSide(
            color: cs.outlineVariant.withAlpha(120),
            width: AppSizes.borderWidth,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 76.0,
            child: Text(
              AppStrings.appointmentColTime.toUpperCase(),
              style: labelStyle,
            ),
          ),
          const SizedBox(width: AppSizes.p12),
          Expanded(
            flex: 5,
            child: Text(
              AppStrings.appointmentColPatient.toUpperCase(),
              style: labelStyle,
            ),
          ),
          const SizedBox(width: AppSizes.p12),
          Expanded(
            flex: 3,
            child: Text(
              AppStrings.appointmentColType.toUpperCase(),
              style: labelStyle,
            ),
          ),
          if (showDoctor) ...[
            const SizedBox(width: AppSizes.p12),
            Expanded(
              flex: 4,
              child: Text(
                AppStrings.appointmentColDoctor.toUpperCase(),
                style: labelStyle,
              ),
            ),
          ],
          const SizedBox(width: AppSizes.p12),
          SizedBox(
            width: 120.0,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                AppStrings.appointmentColStatus.toUpperCase(),
                style: labelStyle,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.p8 + 36.0),
        ],
      ),
    );
  }
}
