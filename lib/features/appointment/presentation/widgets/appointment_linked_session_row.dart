/// Interactive row displaying a linked session with time, type, status, and navigation.
///
/// Rule 1 — keep files under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_badge_colors.dart';
import 'package:spine_clinic_app/shared/widgets/app_badge.dart';

/// Single tappable row representing a linked session on the same day.
class AppointmentLinkedSessionRow extends StatelessWidget {
  const AppointmentLinkedSessionRow({super.key, required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeColors = appointment.status.badgeColors(context);

    return InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r8)),
      onTap: () {
        context.replace(
          AppRoutes.appointmentDetail.replaceAll(':id', appointment.id),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSizes.p6,
          horizontal: AppSizes.p4,
        ),
        child: Row(
          children: [
            Text(
              Formatters.formatTime(appointment.scheduledAt),
              style: AppTextStyles.captionBold.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: AppSizes.p12),
            Expanded(
              child: Text(
                appointment.type.displayLabel,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            AppBadge(
              label: appointment.status.displayLabel,
              textColor: badgeColors.textColor,
              backgroundColor: badgeColors.backgroundColor,
            ),
            const SizedBox(width: AppSizes.p4),
            Icon(
              Icons.chevron_right_rounded,
              size: AppSizes.iconSmall,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
