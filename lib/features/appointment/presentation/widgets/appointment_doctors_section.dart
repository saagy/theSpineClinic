/// Doctors section for the appointment detail screen.
///
/// Renders active doctors with replacement labels and a collapsible
/// audit trail section for inactive (swapped-out) doctor assignments.
///
/// AGENT_CONTEXT §5 Rules 5 & 9 — display logic for appointment doctors.
/// Rule 1 — extracted sub-widget to keep files under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_avatar.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';

/// Displays the active and inactive doctor assignments for an appointment.
class AppointmentDoctorsSection extends StatelessWidget {
  /// Creates an [AppointmentDoctorsSection].
  const AppointmentDoctorsSection({
    super.key,
    required this.activeDoctors,
    required this.inactiveDoctors,
  });

  /// Doctors currently assigned and active on this appointment.
  final List<AppointmentDoctorDetail> activeDoctors;

  /// Doctors who were swapped out — displayed in a collapsible audit trail.
  final List<AppointmentDoctorDetail> inactiveDoctors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Active doctors card
          SectionCard(
            title: AppStrings.doctors,
            child: activeDoctors.isEmpty
                ? Text(
                    AppStrings.noAssignedDoctors,
                    style: AppTextStyles.bodySecondary,
                  )
                : Column(
                    children: activeDoctors.map(_buildActiveDoctorRow).toList(),
                  ),
          ),

          // Inactive doctors — collapsible audit trail
          if (inactiveDoctors.isNotEmpty) ...[
            const SizedBox(height: AppSizes.p12),
            _InactiveDoctorsExpansion(inactiveDoctors: inactiveDoctors),
          ],
        ],
      ),
    );
  }

  /// Builds a single active doctor row with optional "Covering Dr. X" label.
  Widget _buildActiveDoctorRow(AppointmentDoctorDetail detail) {
    return Padding(
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
                    if (!detail.doctor.isActive) ...[
                      const SizedBox(width: AppSizes.p6),
                      Text(
                        AppStrings.deactivated,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
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
    );
  }
}

/// Collapsible section for inactive (swapped-out) doctor audit trail.
class _InactiveDoctorsExpansion extends StatelessWidget {
  const _InactiveDoctorsExpansion({required this.inactiveDoctors});

  final List<AppointmentDoctorDetail> inactiveDoctors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSizes.borderRadiusCard,
        border: Border.all(color: AppColors.border, width: AppSizes.borderWidth),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSizes.p16,
          0,
          AppSizes.p16,
          AppSizes.p16,
        ),
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          AppStrings.originalDoctors,
          style: AppTextStyles.captionMedium,
        ),
        children: inactiveDoctors.map(_buildInactiveRow).toList(),
      ),
    );
  }

  Widget _buildInactiveRow(AppointmentDoctorDetail detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p4),
      child: Row(
        children: [
          Icon(
            Icons.person_off_rounded,
            size: AppSizes.iconSmall,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: AppSizes.p8),
          Text(
            detail.doctor.fullName,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}
