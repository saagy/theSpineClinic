import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';

/// Scheduled: flat "Cancel Appointment" + expanded teal "Check In" pill.
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
        Flexible(
          flex: 1,
          child: _flatCancelButton(loading: loading, onCancel: onCancel),
        ),
        const SizedBox(width: AppSizes.p12),
        Flexible(
          flex: 2,
          child: AppButton(
            labelText: 'Check In',
            onPressed: loading ? null : onCheckIn,
            isLoading: loading,
            shape: AppButtonShape.pill,
          ),
        ),
      ],
    );
  }
}

/// Checked-In: flat "Cancel Appointment" + expanded secondary "Undo Check-In" pill.
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
        Flexible(
          flex: 1,
          child: _flatCancelButton(loading: loading, onCancel: onCancel),
        ),
        const SizedBox(width: AppSizes.p12),
        Flexible(
          flex: 2,
          child: AppButton(
            labelText: 'Undo Check-In',
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
      labelText: 'Restore Appointment',
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
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8),
    ),
    child: Text(
      'Cancel Appointment',
      style: AppTextStyles.button.copyWith(
        color: AppColors.error,
        fontSize: 14,
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    ),
  );
}
