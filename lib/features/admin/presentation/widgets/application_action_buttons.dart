import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';

/// Renders a touch-friendly Approve/Reject button row for pending doctor applications.
class ApplicationActionButtons extends StatelessWidget {
  /// Creates an [ApplicationActionButtons] instance.
  const ApplicationActionButtons({
    super.key,
    required this.onApprove,
    required this.onReject,
    this.isLoading = false,
  });

  /// Action triggered when the user taps Approve.
  final VoidCallback onApprove;

  /// Action triggered when the user taps Reject.
  final VoidCallback onReject;

  /// Whether the actions are currently processing in the background.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            labelText: AppStrings.reject,
            onPressed: isLoading ? null : onReject,
            variant: AppButtonVariant.danger,
          ),
        ),
        const SizedBox(width: AppSizes.p12),
        Expanded(
          child: AppButton(
            labelText: AppStrings.approve,
            onPressed: isLoading ? null : onApprove,
            variant: AppButtonVariant.success,
          ),
        ),
      ],
    );
  }
}
