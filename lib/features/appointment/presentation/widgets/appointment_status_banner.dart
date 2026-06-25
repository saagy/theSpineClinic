import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
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
        bg = AppColors.neutralBg;
        fg = AppColors.neutral;
        icon = Icons.schedule_rounded;
        title = 'Scheduled';
        description = 'Patient expected.';
        break;
      case AppointmentStatus.checkedIn:
        bg = AppColors.successBg;
        fg = AppColors.success;
        icon = Icons.check_circle_outline_rounded;
        title = 'Checked In';
        description = 'Patient has arrived.';
        break;
      case AppointmentStatus.cancelled:
        bg = AppColors.errorBg;
        fg = AppColors.error;
        icon = Icons.cancel_outlined;
        title = 'Cancelled';
        description = 'Appointment cancelled.';
        break;
      case AppointmentStatus.completed:
        bg = colorScheme.surface;
        fg = AppColors.textSecondary;
        icon = Icons.task_alt_rounded;
        title = 'Completed';
        description = 'Session finished.';
        break;
      case AppointmentStatus.noShow:
        bg = AppColors.warningBg;
        fg = AppColors.warning;
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
                      color: fg == AppColors.textSecondary 
                          ? AppColors.textMuted 
                          : fg.withValues(alpha: 0.9),
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
