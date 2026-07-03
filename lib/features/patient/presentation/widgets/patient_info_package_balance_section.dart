/// Package balance section for the patient info tab.
library;

import 'package:flutter/material.dart';

import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/package_balance_edit_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/eyebrow_label.dart';

class PatientInfoPackageBalanceSection extends StatelessWidget {
  const PatientInfoPackageBalanceSection({
    super.key,
    required this.patient,
    required this.isDoctor,
  });

  final Patient patient;
  final bool isDoctor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EyebrowLabel(
            text: AppStrings.packageBalance,
            action: isDoctor ? null : _PackageBalanceEditAction(patient),
          ),
          const SizedBox(height: AppSizes.p16),
          Row(
            children: [
              Expanded(
                child: _BalanceNumber(
                  label: AppStrings.ptSessionsBucket,
                  value: patient.sessionBalance,
                ),
              ),
              const SizedBox(width: AppSizes.p16),
              Expanded(
                child: _BalanceNumber(
                  label: AppStrings.tractionSessionsBucket,
                  value: patient.tractionBalance,
                  useTertiaryColor: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PackageBalanceEditAction extends StatelessWidget {
  const _PackageBalanceEditAction(this.patient);

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface.withAlpha(0),
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r12)),
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => PackageBalanceEditDialog(patient: patient),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.edit_outlined,
                size: AppSizes.iconSmall,
                color: cs.primary,
              ),
              const SizedBox(width: AppSizes.p4),
              Text(
                AppStrings.edit,
                style: AppTextStyles.captionMedium.copyWith(color: cs.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceNumber extends StatelessWidget {
  const _BalanceNumber({
    required this.label,
    required this.value,
    this.useTertiaryColor = false,
  });

  final String label;
  final int value;
  final bool useTertiaryColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bool isWarning = value <= 0;
    final Color color = isWarning
        ? cs.error
        : useTertiaryColor
        ? cs.tertiary
        : cs.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$value', style: AppTextStyles.numberLarge.copyWith(color: color)),
        const SizedBox(height: AppSizes.p4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
