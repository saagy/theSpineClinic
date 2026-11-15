/// Role- and status-guarded action buttons for the appointment detail screen.
///
/// SCHEDULED → "Cancel", "No-show" once the visit's day has come, "Check In".
/// CHECKED_IN → "Cancel" + "Undo Check-In".
/// NO_SHOW → "Undo no-show". CANCELLED → "Restore Appointment".
/// An outcome recorded on an earlier day is changed only by payment staff,
/// who are asked for a reason; others see why there is nothing to do.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/agenda_status_action.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_status_actions.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';

/// Displays role- and status-guarded action buttons in a low-profile sticky bar.
class AppointmentActionButtons extends ConsumerStatefulWidget {
  const AppointmentActionButtons({
    super.key,
    required this.appointment,
    required this.userRole,
  });
  final Appointment appointment;
  final UserRole userRole;

  @override
  ConsumerState<AppointmentActionButtons> createState() => _AppointmentActionButtonsState();
}

class _AppointmentActionButtonsState extends ConsumerState<AppointmentActionButtons> {
  bool _loading = false;

  Appointment get _appointment => widget.appointment;

  @override
  Widget build(BuildContext context) {
    final bool canChange = canChangeVisitOutcome(_appointment, ref.watch(currentUserProvider).value);
    final Widget child = switch (_appointment.status) {
      AppointmentStatus.scheduled => KeyedSubtree(
        key: const ValueKey('scheduled_actions'),
        child: ScheduledActions(
          loading: _loading,
          onCheckIn: () => _act(AppointmentStatus.checkedIn, AppStrings.checkInPatient, AppStrings.confirmCheckIn),
          onCancel: () => _act(
            AppointmentStatus.cancelled,
            AppStrings.cancelAppointment,
            AppStrings.confirmCancel,
            destructive: true,
          ),
          onNoShow: visitDayHasCome(_appointment)
              ? () => _act(AppointmentStatus.noShow, AppStrings.visit.markNoShow, AppStrings.visit.confirmNoShow)
              : null,
        ),
      ),
      _ when !canChange => KeyedSubtree(
        key: const ValueKey('locked_actions'),
        child: Text(
          AppStrings.visit.lockedForDesk,
          style: AppTextStyles.bodySecondary.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
      AppointmentStatus.checkedIn => KeyedSubtree(
        key: const ValueKey('checked_in_actions'),
        child: CheckedInActions(
          loading: _loading,
          onRevert: () => _act(AppointmentStatus.scheduled, AppStrings.revertToScheduled, AppStrings.confirmRevert),
          onCancel: () => _act(
            AppointmentStatus.cancelled,
            AppStrings.cancelAppointment,
            AppStrings.confirmCancel,
            destructive: true,
          ),
        ),
      ),
      AppointmentStatus.noShow => KeyedSubtree(
        key: const ValueKey('no_show_actions'),
        child: SingleRestoreAction(
          label: AppStrings.visit.undoNoShow,
          loading: _loading,
          onPressed: () => _act(AppointmentStatus.scheduled, AppStrings.visit.undoNoShow, AppStrings.visit.confirmUndoNoShow),
        ),
      ),
      AppointmentStatus.cancelled => KeyedSubtree(
        key: const ValueKey('cancelled_actions'),
        child: SingleRestoreAction(
          label: AppStrings.restoreAppointment,
          loading: _loading,
          onPressed: () => _act(AppointmentStatus.scheduled, AppStrings.restoreToScheduled, AppStrings.confirmRestore),
        ),
      ),
    };

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
        child: child,
      ),
    );
  }

  /// Confirms, then records [status]. An earlier day's outcome also asks for
  /// a reason (in [changeVisitStatus]).
  Future<void> _act(
    AppointmentStatus status,
    String title,
    String message, {
    bool destructive = false,
  }) async {
    if (_loading) return;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmationDialog(title: title, message: message, isDestructive: destructive),
    );
    if (ok != true || !mounted) return;
    setState(() => _loading = true);
    try {
      await changeVisitStatus(context, ref, appointment: _appointment, status: status);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
