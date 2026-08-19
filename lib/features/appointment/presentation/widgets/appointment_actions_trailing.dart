import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/all_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/doctor_schedule_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_badge_colors.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_list_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_badge.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';

part 'appointment_actions_trailing_handlers.dart';

/// Trailing actions for appointment rows (badge and three-dot context menu).
class AppointmentActionsTrailing extends ConsumerStatefulWidget {
  const AppointmentActionsTrailing({
    super.key,
    required this.appointment,
    this.onStatusChanged,
    this.showBadge = true,
  });

  final Appointment appointment;
  final VoidCallback? onStatusChanged;
  final bool showBadge;

  @override
  ConsumerState<AppointmentActionsTrailing> createState() =>
      _AppointmentActionsTrailingState();
}

class _AppointmentActionsTrailingState
    extends ConsumerState<AppointmentActionsTrailing>
    with _AppointmentActionsTrailingHandlers {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final bool isAuthorizedStaff = user != null &&
        (user.role == UserRole.receptionist ||
            user.role == UserRole.superAdmin ||
            user.role == UserRole.doctor);
    final AppointmentStatus status = widget.appointment.status;
    final bool hasMenu = isAuthorizedStaff &&
        (status == AppointmentStatus.scheduled ||
            status == AppointmentStatus.checkedIn ||
            status == AppointmentStatus.cancelled);

    if (!hasMenu && !widget.showBadge) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showBadge) _badge(status),
        if (hasMenu) ...[
          if (widget.showBadge) const SizedBox(width: AppSizes.p4),
          _buildContextMenu(status),
        ],
      ],
    );
  }

  Widget _buildContextMenu(AppointmentStatus status) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz_rounded, color: cs.onSurfaceVariant),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      splashRadius: AppSizes.iconDefault,
      color: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.r12)),
      ),
      elevation: 1,
      position: PopupMenuPosition.under,
      enabled: !_isProcessing,
      onSelected: (String value) {
        switch (value) {
          case 'check_in':
            _handleCheckIn();
          case 'cancel':
            _handleCancel();
          case 'revert':
            _handleRevertToScheduled();
          case 'restore':
            _handleRestore();
        }
      },
      itemBuilder: (BuildContext context) => _buildMenuItems(status),
    );
  }

  List<PopupMenuItem<String>> _buildMenuItems(AppointmentStatus status) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ClinicColors clinic = ClinicColors.of(context);
    switch (status) {
      case AppointmentStatus.scheduled:
        return [
          _menuItem(
            'check_in',
            Icons.check_circle_outline_rounded,
            clinic.success,
            AppStrings.checkIn,
          ),
          _menuItem(
            'cancel',
            Icons.close_rounded,
            cs.error,
            AppStrings.cancelAppointment,
          ),
        ];
      case AppointmentStatus.checkedIn:
        return [
          _menuItem(
            'revert',
            Icons.undo_rounded,
            cs.onSurfaceVariant,
            AppStrings.revertToScheduled,
          ),
          _menuItem(
            'cancel',
            Icons.close_rounded,
            cs.error,
            AppStrings.cancelAppointment,
          ),
        ];
      case AppointmentStatus.cancelled:
        return [
          _menuItem(
            'restore',
            Icons.refresh_rounded,
            clinic.success,
            AppStrings.restoreAppointment,
          ),
        ];
    }
  }

  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    Color iconColor,
    String label,
  ) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return PopupMenuItem<String>(
      value: value,
      height: AppSizes.buttonHeightSmall,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: AppSizes.p8),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _badge(AppointmentStatus status) {
    final t = widget.appointment.scheduledAt.toLocal();
    final bool isPastScheduled = status == AppointmentStatus.scheduled &&
        DateUtils.dateOnly(t).isBefore(DateUtils.dateOnly(DateTime.now()));

    if (isPastScheduled) {
      final ClinicColors clinic = ClinicColors.of(context);
      return AppBadge(
        label: AppStrings.pastScheduledNeedsAction,
        textColor: clinic.warning,
        backgroundColor: clinic.warningContainer,
      );
    }

    final AppointmentBadgeColors badge = status.badgeColors(context);
    return AppBadge(
      label: status.displayLabel,
      textColor: badge.textColor,
      backgroundColor: badge.backgroundColor,
    );
  }
}
