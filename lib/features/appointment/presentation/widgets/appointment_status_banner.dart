import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';

/// An edge-to-edge status ribbon displaying the appointment status.
/// Contains no borders or border radius; sits flush against the page header.
class AppointmentStatusBanner extends StatelessWidget {
  const AppointmentStatusBanner({
    super.key,
    required this.status,
    required this.scheduledAt,
  });

  final AppointmentStatus status;
  final DateTime scheduledAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ClinicColors clinic = ClinicColors.of(context);

    final Color bg;
    final Color fg;
    final IconData icon;
    final String description;
    final bool isPastScheduled =
        status == AppointmentStatus.scheduled &&
        DateUtils.dateOnly(
          scheduledAt.toLocal(),
        ).isBefore(DateUtils.dateOnly(DateTime.now()));

    switch (status) {
      case AppointmentStatus.scheduled:
        bg = isPastScheduled
            ? clinic.warningContainer
            : colorScheme.onSurface.withValues(alpha: 0.05);
        fg = isPastScheduled ? clinic.warning : colorScheme.onSurfaceVariant;
        icon = isPastScheduled
            ? Icons.warning_amber_rounded
            : Icons.schedule_rounded;
        description = isPastScheduled
            ? AppStrings.pastScheduledNeedsAction
            : AppStrings.patientExpected;
        break;
      case AppointmentStatus.checkedIn:
        bg = clinic.successContainer;
        fg = clinic.success;
        icon = Icons.check_circle_outline_rounded;
        description = AppStrings.patientArrived;
        break;
      case AppointmentStatus.cancelled:
        bg = colorScheme.errorContainer;
        fg = colorScheme.error;
        icon = Icons.cancel_outlined;
        description = AppStrings.appointmentCancelledDescription;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p24,
        vertical: AppSizes.p12,
      ),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          left: BorderSide(color: fg, width: AppSizes.p4),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: AppSizes.iconDefault),
          const SizedBox(width: AppSizes.p12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text:
                        '${isPastScheduled ? AppStrings.scheduled : status.displayLabel}: ',
                    style: AppTextStyles.bodyBold.copyWith(color: fg),
                  ),
                  TextSpan(
                    text: description,
                    style: AppTextStyles.bodySecondary.copyWith(
                      color: fg.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
