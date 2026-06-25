/// Status-specific bottom action layouts for the appointment detail screen.
///
/// Scheduled / Checked-In: flat TextButton (Cancel) + Expanded primary pill.
/// This gives a clear primary/secondary hierarchy and keeps the bar short.
///
/// Cancelled: single full-width secondary "Restore Appointment".
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';

/// Scheduled: flat "Cancel" + expanded teal "Check In" pill.
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
    return Row(
      children: [
        _flatCancelButton(loading: loading, onCancel: onCancel),
        const SizedBox(width: AppSizes.p12),
        Expanded(
          child: AppButton(
            labelText: AppStrings.checkIn,
            onPressed: loading ? null : onCheckIn,
            isLoading: loading,
            shape: AppButtonShape.pill,
          ),
        ),
      ],
    );
  }
}

/// Checked-In: flat "Cancel" + expanded secondary "Undo Check-In" pill.
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
    return Row(
      children: [
        _flatCancelButton(loading: loading, onCancel: onCancel),
        const SizedBox(width: AppSizes.p12),
        Expanded(
          child: AppButton(
            labelText: AppStrings.undoCheckIn,
            onPressed: loading ? null : onRevert,
            isLoading: loading,
            variant: AppButtonVariant.secondary,
            shape: AppButtonShape.pill,
          ),
        ),
      ],
    );
  }
}

/// Cancelled: single full-width secondary "Restore Appointment".
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
    return AppButton(
      labelText: AppStrings.restoreToScheduled,
      onPressed: loading ? null : onRestore,
      isLoading: loading,
      variant: AppButtonVariant.secondary,
      shape: AppButtonShape.pill,
    );
  }
}

// ── Private shared widget ─────────────────────────────────────────────

/// Borderless flat text button — quiet secondary action.
Widget _flatCancelButton({required bool loading, required VoidCallback onCancel}) {
  return TextButton(
    onPressed: loading ? null : onCancel,
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p12),
    ),
    child: Text(
      AppStrings.cancel,
      style: AppTextStyles.button.copyWith(color: AppColors.textSecondary),
    ),
  );
}
