import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/shared/widgets/app_avatar.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';

class RecordPaymentPatientHeader extends StatelessWidget {
  const RecordPaymentPatientHeader({super.key, required this.patient});
  final Patient patient;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SectionCard(
      title: AppStrings.patientDisplayName,
      child: Row(
        children: [
          AppAvatar(
            name: patient.fullName,
            color: cs.primaryContainer,
            radius: AppSizes.p24,
          ),
          const SizedBox(width: AppSizes.p16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.fullName,
                  style: AppTextStyles.bodyBold.copyWith(color: cs.onSurface),
                ),
                const SizedBox(height: AppSizes.p4),
                Text(
                  patient.phoneNumber,
                  style: AppTextStyles.bodySecondary.copyWith(
                    color: cs.onSurfaceVariant,
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
