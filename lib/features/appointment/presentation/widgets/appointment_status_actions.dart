import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';

/// Scheduled: asymmetric row with text "Cancel Appt." (flex 10) + solid teal "Check In" button (flex 19).
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
          flex: 10,
          child: _flatCancelButton(context: context, loading: loading, onCancel: onCancel),
        ),
        const SizedBox(width: AppSizes.p12),
        Flexible(
          flex: 19,
          child: AppButton(
            labelText: 'Check In',
            onPressed: loading ? null : onCheckIn,
            isLoading: loading,
            shape: AppButtonShape.rounded12,
          ),
        ),
      ],
    );
  }
}

/// Checked-In: asymmetric row with text "Cancel Appt." (flex 10) + secondary "Undo Check-In" button (flex 19).
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
          flex: 10,
          child: _flatCancelButton(context: context, loading: loading, onCancel: onCancel),
        ),
        const SizedBox(width: AppSizes.p12),
        Flexible(
          flex: 19,
          child: AppButton(
            labelText: 'Undo Check-In',
            onPressed: loading ? null : onRevert,
            isLoading: loading,
            variant: AppButtonVariant.secondary,
            shape: AppButtonShape.rounded12,
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
      shape: AppButtonShape.rounded12,
    );
  }
}

// ── Private shared widget ─────────────────────────────────────────────

/// Borderless flat text button — quiet secondary action.
Widget _flatCancelButton({
  required BuildContext context,
  required bool loading,
  required VoidCallback onCancel,
}) {
  return TextButton(
    onPressed: loading ? null : onCancel,
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p4),
      minimumSize: const Size.fromHeight(AppSizes.tappableMin),
    ),
    child: AutoSizeText(
      'Cancel Appt.',
      style: AppTextStyles.button.copyWith(
        color: Theme.of(context).colorScheme.error,
        fontSize: 14,
      ),
      maxLines: 1,
      minFontSize: 10,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    ),
  );
}
