/// Contact details section for the patient info tab.
library;

import 'package:flutter/material.dart';

import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
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
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
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
          child: Text(
            value,
            style: AppTextStyles.bodyBold.copyWith(color: cs.onSurface),
          ),
        ),
      ],
    );
  }
}
