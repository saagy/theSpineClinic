/// Interactive row displaying a linked session with time, type, status, and navigation.
///
/// Rule 1 — keep files under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_badge_colors.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_badge.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';

/// Single flat tappable row representing a linked session on the same day.
class AppointmentLinkedSessionRow extends ConsumerWidget {
  const AppointmentLinkedSessionRow({super.key, required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final badgeColors = appointment.status.badgeColors(context);

    final user = ref.watch(currentUserProvider).value;
    final bool isDoctor = user?.role == UserRole.doctor;
    final canAccessAsync = isDoctor
        ? ref.watch(
            canAccessAppointmentProvider(
              appointmentId: appointment.id,
              patientId: appointment.patientId,
            ),
          )
        : const AsyncValue.data(true);
    final bool canAccess = canAccessAsync.value ?? !isDoctor;

    return InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r8)),
      onTap: () {
        if (!canAccess) {
          AppSnackbar.show(
            context,
            message: AppStrings.errorDatabasePermissionDenied,
            variant: AppSnackbarVariant.error,
          );
          return;
        }
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
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: AppSizes.p12),
            Expanded(
              child: Text(
                appointment.type.displayLabel,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colorScheme.onSurface,
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
            if (canAccess) ...[
              const SizedBox(width: AppSizes.p4),
              Icon(
                Icons.chevron_right_rounded,
                size: AppSizes.iconSmall,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
