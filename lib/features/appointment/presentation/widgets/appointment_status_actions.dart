/// Status-specific bottom action layouts for the appointment detail screen.
///
/// All states use an identical structural Row of two equal-width Expanded
/// buttons (h=48, r=14). Only the right-hand button's style and label change
/// per status — no vertical stacking, no width shifts.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';

/// Shared geometry constants — identical across every status.
const double _kH = 48;
const double _kR = 14;

/// Fixed 50/50 grid for SCHEDULED: Cancel (outlined) | Check In (teal-filled).
class ScheduledActions extends StatelessWidget {
  const ScheduledActions({
    super.key,
    required this.loading,
    required this.onCheckIn,
    required this.onCancel,
  });
  final bool loading;
  final VoidCallback onCheckIn;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _cancelButton(loading: loading, onCancel: onCancel)),
      const SizedBox(width: AppSizes.p12),
      Expanded(child: _checkInButton(loading: loading, onCheckIn: onCheckIn)),
    ]);
  }
}

/// Fixed 50/50 grid for CHECKED IN: Cancel (outlined) | Undo Check-In (outlined).
/// Structurally identical to Scheduled — only the right button changes.
class CheckedInActions extends StatelessWidget {
  const CheckedInActions({
    super.key,
    required this.loading,
    required this.onRevert,
    required this.onCancel,
  });
  final bool loading;
  final VoidCallback onRevert;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _cancelButton(loading: loading, onCancel: onCancel)),
      const SizedBox(width: AppSizes.p12),
      Expanded(child: _undoButton(loading: loading, onRevert: onRevert)),
    ]);
  }
}

/// Cancelled: single full-width outlined teal "Restore Appointment".
class CancelledActions extends StatelessWidget {
  const CancelledActions({
    super.key,
    required this.loading,
    required this.onRestore,
  });
  final bool loading;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kH,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(_kR))),
        ),
        onPressed: loading ? null : onRestore,
        child: const Text(AppStrings.restoreToScheduled),
      ),
    );
  }
}

// ── Private shared button builders ────────────────────────────────────

/// Cancel button — identical across Scheduled and Checked In.
Widget _cancelButton({required bool loading, required VoidCallback onCancel}) {
  return SizedBox(
    height: _kH,
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: const BorderSide(color: AppColors.border),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(_kR))),
      ),
      onPressed: loading ? null : onCancel,
      child: const Text(AppStrings.cancelAppointment),
    ),
  );
}

/// Teal-filled Check In button.
Widget _checkInButton({
  required bool loading,
  required VoidCallback onCheckIn,
}) {
  return SizedBox(
    height: _kH,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        disabledBackgroundColor: AppColors.textMuted.withAlpha(50),
        foregroundColor: AppColors.textOnPrimary,
        disabledForegroundColor: AppColors.textMuted,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(_kR))),
        elevation: 0,
      ),
      onPressed: loading ? null : onCheckIn,
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.textOnPrimary))
          : const Text(AppStrings.checkIn),
    ),
  );
}

/// Gray-outlined Undo Check-In button.
Widget _undoButton({required bool loading, required VoidCallback onRevert}) {
  return SizedBox(
    height: _kH,
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        side: const BorderSide(color: AppColors.border),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(_kR))),
      ),
      onPressed: loading ? null : onRevert,
      child: const Text(AppStrings.undoCheckIn),
    ),
  );
}
