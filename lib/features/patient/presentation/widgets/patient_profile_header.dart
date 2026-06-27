/// Expanded patient profile header — initials avatar, bold name, phone,
/// clinic badge, dual PT/Traction balance chip with inline edit action.
///
/// Vertical hierarchy with subtle primaryContainer tint for visual identity.
///
/// Rule 15/16 — all colours via Theme.of(context).colorScheme.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_balance_chip.dart';
import 'package:spine_clinic_app/shared/widgets/app_avatar.dart';

class PatientProfileHeader extends StatelessWidget {
  const PatientProfileHeader({
    super.key,
    required this.patient,
    required this.isDoctor,
  });
  final Patient patient;
  final bool isDoctor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.p20, AppSizes.p16, AppSizes.p20, AppSizes.p16),
      decoration: BoxDecoration(
        color: cs.surface,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppAvatar(name: patient.fullName, radius: AppSizes.avatarLarge / 2),
          const SizedBox(width: AppSizes.p16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(patient.fullName, style: AppTextStyles.headingMedium),
                const SizedBox(height: AppSizes.p4),
                Text(patient.phoneNumber, style: AppTextStyles.bodySecondary),
                const SizedBox(height: AppSizes.p8),
                Wrap(
                  spacing: AppSizes.p8,
                  runSpacing: AppSizes.p4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _MiniBadge(
                      label: patient.clinic.displayLabel,
                      color: cs.primary,
                    ),
                    PatientBalanceChip(
                      sessionBalance: patient.sessionBalance,
                      tractionBalance: patient.tractionBalance,
                      patient: patient,
                      canEdit: !isDoctor,
                    ),
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
          horizontal: AppSizes.p8, vertical: AppSizes.p4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(AppSizes.r6),
      ),
      child: Text(
        label,
        style: AppTextStyles.captionMedium.copyWith(color: color),
      ),
    );
  }
}
