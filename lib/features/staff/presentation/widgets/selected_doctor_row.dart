import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/shared/widgets/app_avatar.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';

/// Renders a single selected doctor as an avatar + name row with an optional
/// remove button. Used by [AppDoctorMultiSelectField].
class SelectedDoctorRow extends StatelessWidget {
  /// Creates a [SelectedDoctorRow].
  const SelectedDoctorRow({
    super.key,
    required this.doctor,
    required this.showRemove,
    required this.isLastDoctor,
    required this.onRemove,
  });

  final Staff doctor;
  final bool showRemove;
  final bool isLastDoctor;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p4),
      child: Row(
        children: [
          AppAvatar(name: doctor.fullName, radius: 18),
          const SizedBox(width: AppSizes.p8),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(doctor.fullName,
                      style: AppTextStyles.bodyBold,
                      overflow: TextOverflow.ellipsis),
                ),
                if (!doctor.isActive) ...[
                  const SizedBox(width: AppSizes.p6),
                  Text(AppStrings.deactivated,
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
          if (showRemove)
            GestureDetector(
              onTap: () {
                if (isLastDoctor) {
                  AppSnackbar.show(
                    context,
                    message: 'At least one doctor is required.',
                    variant: AppSnackbarVariant.error,
                  );
                  return;
                }
                onRemove();
              },
              child: const Icon(Icons.close,
                  size: AppSizes.iconSmall,
                  color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }
}
