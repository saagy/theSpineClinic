/// Doctors section for the appointment detail screen.
///
/// Renders active doctors with replacement labels and a collapsible
/// audit trail section for inactive (swapped-out) doctor assignments.
///
/// Rule 1 — extracted sub-widget to keep files under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_avatar.dart';

/// Displays the active and inactive doctor assignments for an appointment.
class AppointmentDoctorsSection extends StatelessWidget {
  const AppointmentDoctorsSection({
    super.key,
    required this.activeDoctors,
    required this.inactiveDoctors,
  });

  final List<AppointmentDoctorDetail> activeDoctors;
  final List<AppointmentDoctorDetail> inactiveDoctors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p24,
        AppSizes.p8,
        AppSizes.p24,
        AppSizes.p8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ASSIGNED DOCTORS',
            style: AppTextStyles.captionMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSizes.p8),
          
          activeDoctors.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
                  child: Text(
                    AppStrings.noAssignedDoctors,
                    style: AppTextStyles.bodySecondary,
                  ),
                )
              : Column(
                  children: activeDoctors.map(_buildActiveDoctorRow).toList(),
                ),

          if (inactiveDoctors.isNotEmpty) ...[
            _InactiveDoctorsExpansion(inactiveDoctors: inactiveDoctors),
          ],
          const SizedBox(height: AppSizes.p16),
          const Divider(color: AppColors.border, height: 1.0, thickness: 0.5),
        ],
      ),
    );
  }

  Widget _buildActiveDoctorRow(AppointmentDoctorDetail detail) {
    final bool isDeactivated = !detail.doctor.isActive;
    return Opacity(
      opacity: isDeactivated ? 0.5 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.p6),
        child: Row(
          children: [
            AppAvatar(
              name: detail.doctor.fullName,
              radius: 18,
            ),
            const SizedBox(width: AppSizes.p8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          detail.doctor.fullName,
                          style: AppTextStyles.bodyBold,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isDeactivated) ...[
                        const SizedBox(width: AppSizes.p6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warningBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Deactivated',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (detail.assignment.isReplacement &&
                      detail.replacedDoctor != null)
                    Text(
                      '${AppStrings.coveringDr} ${detail.replacedDoctor!.fullName}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InactiveDoctorsExpansion extends StatelessWidget {
  const _InactiveDoctorsExpansion({required this.inactiveDoctors});

  final List<AppointmentDoctorDetail> inactiveDoctors;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: AppSizes.p8),
      shape: const Border(),
      collapsedShape: const Border(),
      iconColor: AppColors.textSecondary,
      collapsedIconColor: AppColors.textMuted,
      title: Text(
        AppStrings.originalDoctors,
        style: AppTextStyles.captionMedium.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
      children: inactiveDoctors.map(_buildInactiveRow).toList(),
    );
  }

  Widget _buildInactiveRow(AppointmentDoctorDetail detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p4),
      child: Row(
        children: [
          const Icon(
            Icons.person_off_rounded,
            size: AppSizes.iconSmall,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: AppSizes.p8),
          Text(
            detail.doctor.fullName,
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
