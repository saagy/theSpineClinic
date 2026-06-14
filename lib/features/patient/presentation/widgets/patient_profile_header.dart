/// Rich patient profile header: large initials avatar, bold name,
/// phone, branch badge, and package chip.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/shared/widgets/app_avatar.dart';

/// Fixed header block for the patient profile screen.
class PatientProfileHeader extends StatelessWidget {
  const PatientProfileHeader({super.key, required this.patient});
  final Patient patient;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
          AppSizes.p20, AppSizes.p12, AppSizes.p20, AppSizes.p12),
      child: Row(
        children: [
          AppAvatar(name: patient.fullName, radius: 28),
          const SizedBox(width: AppSizes.p16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(patient.fullName, style: AppTextStyles.headingMedium),
                const SizedBox(height: AppSizes.p4),
                Text(patient.phoneNumber, style: AppTextStyles.bodySecondary),
                const SizedBox(height: AppSizes.p6),
                Row(
                  children: [
                    _MiniBadge(
                        label: patient.clinic.displayLabel,
                        color: AppColors.primary),
                    const SizedBox(width: AppSizes.p8),
                    _PackageChip(balance: patient.packageBalance),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p8, vertical: AppSizes.p2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius:
            const BorderRadius.all(Radius.circular(AppSizes.r6)),
      ),
      child: Text(label,
          style: AppTextStyles.captionMedium
              .copyWith(color: color, fontSize: 11)),
    );
  }
}

class _PackageChip extends StatelessWidget {
  const _PackageChip({required this.balance});
  final int balance;
  @override
  Widget build(BuildContext context) {
    final has = balance > 0;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p8, vertical: AppSizes.p2),
      decoration: BoxDecoration(
        color: has ? AppColors.successBg : AppColors.errorBg,
        borderRadius:
            const BorderRadius.all(Radius.circular(AppSizes.r6)),
      ),
      child: Text(
        has
            ? 'Package: $balance session${balance == 1 ? '' : 's'} left'
            : 'No Package',
        style: AppTextStyles.captionMedium.copyWith(
          color: has ? AppColors.success : AppColors.error,
          fontSize: 11,
        ),
      ),
    );
  }
}
