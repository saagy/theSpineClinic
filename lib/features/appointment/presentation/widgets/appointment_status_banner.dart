import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';

/// An edge-to-edge status ribbon displaying the appointment status.
/// Contains no borders or border radius; sits flush against the page header.
class AppointmentStatusBanner extends StatelessWidget {
  const AppointmentStatusBanner({super.key, required this.status});

  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color bg;
    final Color fg;
    final IconData icon;
    final String title;
    final String description;

    switch (status) {
      case AppointmentStatus.scheduled:
        bg = colorScheme.onSurface.withValues(alpha: 0.05);
        fg = colorScheme.onSurfaceVariant;
        icon = Icons.schedule_rounded;
        title = 'Scheduled';
        description = 'Patient expected.';
        break;
      case AppointmentStatus.checkedIn:
        bg = colorScheme.primaryContainer;
        fg = colorScheme.onPrimaryContainer;
        icon = Icons.check_circle_outline_rounded;
        title = 'Checked In';
        description = 'Patient has arrived.';
        break;
      case AppointmentStatus.cancelled:
        bg = colorScheme.errorContainer;
        fg = colorScheme.error;
        icon = Icons.cancel_outlined;
        title = 'Cancelled';
        description = 'Appointment cancelled.';
        break;
      case AppointmentStatus.completed:
        bg = colorScheme.surface;
        fg = colorScheme.onSurfaceVariant;
        icon = Icons.task_alt_rounded;
        title = 'Completed';
        description = 'Session finished.';
        break;
      case AppointmentStatus.noShow:
        bg = colorScheme.tertiaryContainer;
        fg = colorScheme.onTertiaryContainer;
        icon = Icons.person_off_rounded;
        title = 'No Show';
        description = 'Patient did not arrive.';
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
          left: BorderSide(
            color: fg,
            width: 4.0,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: fg,
            size: AppSizes.iconDefault,
          ),
          const SizedBox(width: AppSizes.p12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$title: ',
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
