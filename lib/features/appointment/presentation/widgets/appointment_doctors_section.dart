/// Doctors section for the appointment detail screen.
///
/// Renders active doctors with replacement labels and a collapsible
/// audit trail section for inactive (swapped-out) doctor assignments.
///
/// Uses the shared [DoctorRow] widget for active doctor rows.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/shared/widgets/eyebrow_label.dart';
import 'package:spine_clinic_app/shared/widgets/doctor_row.dart';

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
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p24,
        AppSizes.p2,
        AppSizes.p24,
        AppSizes.p8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const EyebrowLabel(
            text: AppStrings.doctors,
            isUppercase: false,
          ),
          const SizedBox(height: AppSizes.p8),
          activeDoctors.isEmpty
              ? Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSizes.p8),
                  child: Text(
                    AppStrings.noAssignedDoctors,
                    style: AppTextStyles.bodySecondary,
                  ),
                )
              : Column(
                  children: activeDoctors.map(_buildActiveDoctorRow).toList(),
                ),
          if (inactiveDoctors.isNotEmpty)
            _InactiveDoctorsExpansion(inactiveDoctors: inactiveDoctors),
          const SizedBox(height: AppSizes.p16),
          Divider(color: cs.outlineVariant, height: 1, thickness: 0.5),
        ],
      ),
    );
  }

  Widget _buildActiveDoctorRow(AppointmentDoctorDetail detail) {
    final String? subtitle =
        detail.assignment.isReplacement && detail.replacedDoctor != null
            ? '${AppStrings.coveringDr} ${detail.replacedDoctor!.fullName}'
            : null;

    return DoctorRow(
      name: detail.doctor.fullName,
      isActive: detail.doctor.isActive,
      subtitle: subtitle,
    );
  }
}

class _InactiveDoctorsExpansion extends StatelessWidget {
  const _InactiveDoctorsExpansion({required this.inactiveDoctors});
  final List<AppointmentDoctorDetail> inactiveDoctors;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: AppSizes.p8),
      shape: const Border(),
      collapsedShape: const Border(),
      iconColor: cs.onSurfaceVariant,
      collapsedIconColor: cs.outline,
      title: Text(
        AppStrings.originalDoctors,
        style: AppTextStyles.captionMedium.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
      children: inactiveDoctors.map((d) => _buildInactiveRow(context, d)).toList(),
    );
  }

  Widget _buildInactiveRow(BuildContext context, AppointmentDoctorDetail detail) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p4),
      child: Row(
        children: [
          Icon(
            Icons.person_off_rounded,
            size: AppSizes.iconSmall,
            color: cs.outline,
          ),
          const SizedBox(width: AppSizes.p8),
          Text(
            detail.doctor.fullName,
            style: AppTextStyles.caption
                .copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
