import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/shared/widgets/app_avatar.dart';

/// One row inside [DoctorSearchSheet]. Extracted to keep the sheet's
/// `itemBuilder` body short and the file under the 200-line limit.
class DoctorSearchTile extends StatelessWidget {
  const DoctorSearchTile({
    super.key,
    required this.doctor,
    required this.isSelected,
    required this.onTap,
  });

  final Staff doctor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: AppAvatar(
        name: doctor.fullName,
        radius: 18,
        color: doctor.isActive ? AppColors.primary : AppColors.textMuted,
      ),
      title: Row(children: [
        Flexible(
          child: Text(
            doctor.fullName,
            style: AppTextStyles.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!doctor.isActive) ...[
          const SizedBox(width: AppSizes.p6),
          Text(
            AppStrings.deactivated,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ]),
      subtitle: Text(doctor.email, style: AppTextStyles.caption),
      trailing: isSelected
          ? const Icon(Icons.check_circle,
              color: AppColors.primary, size: AppSizes.iconDefault)
          : const Icon(Icons.circle_outlined,
              color: AppColors.textMuted, size: AppSizes.iconDefault),
      onTap: onTap,
    );
  }
}
