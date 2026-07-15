/// Contact details section for the patient info tab.
library;

import 'package:flutter/material.dart';

import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_phone_options_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/eyebrow_label.dart';

class PatientInfoContactSection extends StatelessWidget {
  const PatientInfoContactSection({super.key, required this.patient});

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const EyebrowLabel(text: AppStrings.contact),
          const SizedBox(height: AppSizes.p12),
          _ContactRow(
            icon: Icons.phone_outlined,
            label: AppStrings.phone,
            value: patient.phoneNumber,
            onTap: () => PatientPhoneOptionsSheet.show(context, patient.phoneNumber),
          ),
          const SizedBox(height: AppSizes.p12),
          _ContactRow(
            icon: Icons.local_hospital_outlined,
            label: AppStrings.clinic,
            value: patient.clinic.displayLabel,
          ),
          const SizedBox(height: AppSizes.p12),
          _ContactRow(
            icon: Icons.medical_services_outlined,
            label: AppStrings.program,
            value: patient.program ?? AppStrings.programNone,
          ),
          const SizedBox(height: AppSizes.p12),
          _ContactRow(
            icon: Icons.event_outlined,
            label: AppStrings.lastVisit,
            value: patient.lastAppointmentDate != null
                ? Formatters.formatDateMedium(patient.lastAppointmentDate!)
                : AppStrings.noVisitsYet,
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: AppSizes.iconDefault, color: cs.primary),
        const SizedBox(width: AppSizes.p12),
        SizedBox(
          width: AppSizes.labelColumnWidth,
          child: Text(
            label,
            style: AppTextStyles.bodySecondary.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: AppSizes.p16),
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                value,
                style: AppTextStyles.bodyBold.copyWith(color: cs.onSurface),
              ),
              if (onTap != null) ...[
                const SizedBox(width: AppSizes.p6),
                Icon(
                  Icons.copy_rounded,
                  size: AppSizes.iconSmall,
                  color: cs.onSurfaceVariant.withAlpha(150),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    final paddedRow = Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSizes.p4,
        horizontal: AppSizes.p4,
      ),
      child: row,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.r8),
          child: paddedRow,
        ),
      );
    }

    return paddedRow;
  }
}
