/// Doctors section for the appointment detail screen.
///
/// Renders active doctors and a collapsible audit trail of past assignments
/// inside a standard Material 3 section card.
///
/// Uses the shared [DoctorRow] widget for active doctor rows.
///
/// Rule 1 — keep files under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/shared/widgets/eyebrow_label.dart';
import 'package:spine_clinic_app/shared/widgets/doctor_row.dart';

/// Section card displaying assigned doctors for an appointment.
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final clinic = ClinicColors.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.p16,
        vertical: AppSizes.p8,
      ),
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        border: Border.all(color: colorScheme.outlineVariant, width: 0.5),
        boxShadow: [clinic.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const EyebrowLabel(text: AppStrings.doctors, isUppercase: false),
          const SizedBox(height: AppSizes.p8),
          if (activeDoctors.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.p4),
              child: Text(
                AppStrings.noAssignedDoctors,
                style: AppTextStyles.bodySecondary.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            Column(
              children: activeDoctors.map(_buildActiveDoctorRow).toList(),
            ),
          if (inactiveDoctors.isNotEmpty)
            _InactiveDoctorsExpansion(inactiveDoctors: inactiveDoctors),
        ],
      ),
    );
  }

  Widget _buildActiveDoctorRow(AppointmentDoctorDetail detail) {
    return DoctorRow(
      name: detail.doctor.fullName,
      isActive: detail.doctor.isActive,
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
      childrenPadding: const EdgeInsets.only(bottom: AppSizes.p4),
      shape: const Border(),
      collapsedShape: const Border(),
      iconColor: cs.onSurfaceVariant,
      collapsedIconColor: cs.outline,
      title: Text(
        AppStrings.previousDoctors,
        style: AppTextStyles.captionMedium.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
      children: inactiveDoctors
          .map((d) => _buildInactiveRow(context, d))
          .toList(),
    );
  }

  Widget _buildInactiveRow(
    BuildContext context,
    AppointmentDoctorDetail detail,
  ) {
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
            style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
