import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/shared/widgets/app_avatar.dart';

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
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p16,
        0,
        AppSizes.p16,
        AppSizes.p8,
      ),
      child: Material(
        color: isSelected ? colors.primaryContainer : colors.surface,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        child: InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Row(
              children: [
                AppAvatar(
                  name: doctor.fullName,
                  radius: AppSizes.avatarSmall / 2,
                ),
                const SizedBox(width: AppSizes.p12),
                Expanded(
                  child: Text(
                    doctor.fullName,
                    style: AppTextStyles.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: isSelected ? colors.primary : colors.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
