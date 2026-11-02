import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

class ApplicationActionButtons extends StatelessWidget {
  const ApplicationActionButtons({
    super.key,
    required this.onApprove,
    required this.onReject,
    this.isLoading = false,
  });
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final bool isLoading;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSizes.p8,
    runSpacing: AppSizes.p8,
    children: [
      TextButton(
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
          minimumSize: const Size(AppSizes.tappableMin, AppSizes.tappableMin),
        ),
        onPressed: isLoading ? null : onReject,
        child: Text(AppStrings.reject, style: AppTextStyles.bodyBold),
      ),
      OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(AppSizes.tappableMin, AppSizes.tappableMin),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r8)),
        ),
        onPressed: isLoading ? null : onApprove,
        child: Text(AppStrings.approve, style: AppTextStyles.bodyBold),
      ),
    ],
  );
}
