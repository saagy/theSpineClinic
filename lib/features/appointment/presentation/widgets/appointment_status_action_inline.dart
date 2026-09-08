import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';

/// Compact mobile icon-only action or status indicator with 40-44px touch target.
class AppointmentStatusActionInline extends ConsumerWidget {
  const AppointmentStatusActionInline({
    super.key,
    required this.status,
    required this.isCheckingIn,
    required this.onCheckIn,
  });

  final AppointmentStatus status;
  final bool isCheckingIn;
  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final clinic = ClinicColors.of(context);

    if (status == AppointmentStatus.scheduled) {
      final user = ref.watch(currentUserProvider).value;
      final canCheckIn =
          user?.role == UserRole.receptionist ||
          user?.role == UserRole.superAdmin ||
          user?.role == UserRole.doctor;

      if (canCheckIn) {
        return Tooltip(
          message: AppStrings.checkIn,
          child: InkResponse(
            onTap: isCheckingIn ? null : onCheckIn,
            radius: 20.0,
            splashColor: cs.primary.withAlpha(30),
            highlightColor: cs.primary.withAlpha(15),
            child: SizedBox.square(
              dimension: AppSizes.tappableMin,
              child: Center(
                child: isCheckingIn
                    ? SizedBox(
                        width: AppSizes.iconSmall,
                        height: AppSizes.iconSmall,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          color: cs.primary,
                        ),
                      )
                    : Icon(
                        Icons.check_circle_outline_rounded,
                        size: AppSizes.iconDefault,
                        color: cs.primary,
                      ),
              ),
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    if (status == AppointmentStatus.checkedIn) {
      return Tooltip(
        message: AppStrings.checkedIn,
        child: SizedBox.square(
          dimension: AppSizes.tappableMin,
          child: Center(
            child: Icon(
              Icons.check_circle_rounded,
              size: AppSizes.iconDefault,
              color: clinic.success,
            ),
          ),
        ),
      );
    }

    if (status == AppointmentStatus.cancelled) {
      return Tooltip(
        message: AppStrings.cancelled,
        child: SizedBox.square(
          dimension: AppSizes.tappableMin,
          child: Center(
            child: Icon(
              Icons.cancel_outlined,
              size: AppSizes.iconDefault,
              color: cs.onSurfaceVariant.withAlpha(160),
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: status.displayLabel,
      child: SizedBox.square(
        dimension: AppSizes.tappableMin,
        child: Center(
          child: Icon(
            Icons.info_outline_rounded,
            size: AppSizes.iconDefault,
            color: cs.onSurfaceVariant.withAlpha(160),
          ),
        ),
      ),
    );
  }
}
