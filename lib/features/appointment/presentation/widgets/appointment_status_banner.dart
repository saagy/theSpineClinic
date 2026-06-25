import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';

/// A static visual status banner displaying the appointment status at the top.
class AppointmentStatusBanner extends StatelessWidget {
  const AppointmentStatusBanner({super.key, required this.status});

  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Get color theme tokens based on status
    final Color bg;
    final Color fg;
    final Color border;
    final IconData icon;
    final String title;
    final String description;

    switch (status) {
      case AppointmentStatus.scheduled:
        bg = AppColors.infoBg;
        fg = AppColors.info;
        border = AppColors.info.withAlpha(25);
        icon = Icons.schedule_rounded;
        title = 'Scheduled';
        description = 'Patient is expected for their session.';
        break;
      case AppointmentStatus.checkedIn:
        bg = AppColors.successBg;
        fg = AppColors.success;
        border = AppColors.success.withAlpha(25);
        icon = Icons.check_circle_outline_rounded;
        title = 'Checked In';
        description = 'Patient has arrived and is ready for treatment.';
        break;
      case AppointmentStatus.cancelled:
        bg = AppColors.errorBg;
        fg = AppColors.error;
        border = AppColors.error.withAlpha(25);
        icon = Icons.cancel_outlined;
        title = 'Cancelled';
        description = 'This appointment was cancelled.';
        break;
      case AppointmentStatus.completed:
        bg = colorScheme.surface;
        fg = AppColors.textSecondary;
        border = AppColors.border;
        icon = Icons.task_alt_rounded;
        title = 'Completed';
        description = 'This treatment session has been completed.';
        break;
      case AppointmentStatus.noShow:
        bg = AppColors.warningBg;
        fg = AppColors.warning;
        border = AppColors.warning.withAlpha(25);
        icon = Icons.person_off_rounded;
        title = 'No Show';
        description = 'Patient did not arrive for their scheduled time.';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p24,
        vertical: AppSizes.p12,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.p16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r12)),
          border: Border.all(color: border, width: 1.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: fg,
              size: AppSizes.iconDefault + 2,
            ),
            const SizedBox(width: AppSizes.p12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyBold.copyWith(color: fg),
                  ),
                  const SizedBox(height: AppSizes.p2),
                  Text(
                    description,
                    style: AppTextStyles.captionMedium.copyWith(
                      color: fg == AppColors.textSecondary 
                          ? AppColors.textMuted 
                          : fg.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
