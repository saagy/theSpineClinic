import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_status_action_inline.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';

/// Clean status indicator or Check-In action for an appointment row.
///
/// On mobile ([isInline] == true), renders a lightweight inline action
/// with little visible chrome and ~44px touch target, opposite the session type.
/// On desktop ([isInline] == false), retains a compact tonal button.
class AppointmentStatusActionBadge extends ConsumerWidget {
  const AppointmentStatusActionBadge({
    super.key,
    required this.status,
    required this.isCheckingIn,
    required this.onCheckIn,
    this.isInline = false,
  });

  final AppointmentStatus status;
  final bool isCheckingIn;
  final VoidCallback onCheckIn;
  final bool isInline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isInline) {
      return AppointmentStatusActionInline(
        status: status,
        isCheckingIn: isCheckingIn,
        onCheckIn: onCheckIn,
      );
    }
    return _buildDesktop(context, ref);
  }

  Widget _buildDesktop(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final clinic = ClinicColors.of(context);

    if (status == AppointmentStatus.scheduled) {
      final user = ref.watch(currentUserProvider).value;
      final canCheckIn = user?.role == UserRole.receptionist ||
          user?.role == UserRole.superAdmin ||
          user?.role == UserRole.doctor;

      if (canCheckIn) {
        return SizedBox(
          height: 32.0,
          child: FilledButton.tonal(
            onPressed: isCheckingIn ? null : onCheckIn,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.r6),
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: isCheckingIn
                ? SizedBox(
                    width: 14.0,
                    height: 14.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: cs.primary,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_rounded, size: 15.0),
                      const SizedBox(width: AppSizes.p4),
                      Flexible(
                        child: Text(
                          AppStrings.checkIn,
                          style: AppTextStyles.captionBold.copyWith(fontSize: 11.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      }
    }

    if (status == AppointmentStatus.checkedIn) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p8,
          vertical: AppSizes.p4,
        ),
        decoration: BoxDecoration(
          color: clinic.successContainer.withAlpha(140),
          borderRadius: BorderRadius.circular(AppSizes.r6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6.0,
              height: 6.0,
              decoration: BoxDecoration(
                color: clinic.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSizes.p6),
            Flexible(
              child: Text(
                AppStrings.checkedIn,
                style: AppTextStyles.captionBold.copyWith(
                  color: clinic.success,
                  fontSize: 11.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p8,
        vertical: AppSizes.p4,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(120),
        borderRadius: BorderRadius.circular(AppSizes.r6),
      ),
      child: Text(
        status == AppointmentStatus.cancelled
            ? AppStrings.cancelled
            : status.displayLabel,
        style: AppTextStyles.caption.copyWith(
          color: cs.onSurfaceVariant.withAlpha(160),
          fontSize: 11.0,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}