import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';

/// Screen body rendering access restriction details when the user role lacks authorization.
class SecurityRestrictionView extends StatelessWidget {
  /// Creates a [SecurityRestrictionView].
  const SecurityRestrictionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSizes.p16),
            Text(
              'Access Denied',
              style: AppTextStyles.headingLarge.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.p8),
            Text(
              'Only the assigned doctor or a super admin can access or modify visit notes.',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.p24),
            AppButton(
              labelText: 'Go Back',
              onPressed: () => Navigator.of(context).pop(),
              variant: AppButtonVariant.secondary,
              fullWidth: false,
            ),
          ],
        ),
      ),
    );
  }
}
