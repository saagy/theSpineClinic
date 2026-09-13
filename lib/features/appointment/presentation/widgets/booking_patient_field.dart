import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_monogram_badge.dart';

class BookingPatientField extends StatelessWidget {
  const BookingPatientField({super.key, this.patient, this.onSelect});
  final Patient? patient;
  final VoidCallback? onSelect;
  @override
  Widget build(BuildContext context) {
    final value = patient;
    if (value == null) {
      return OutlinedButton.icon(
        onPressed: onSelect,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.inputHeight),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r8)),
        ),
        icon: const Icon(Icons.search, size: AppSizes.iconDefault),
        label: const Text(AppStrings.selectPatient, style: AppTextStyles.body),
      );
    }
    return Row(
      children: [
        PatientMonogramBadge(name: value.fullName, size: AppSizes.avatarSmall),
        const SizedBox(width: AppSizes.p12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value.fullName, style: AppTextStyles.bodyBold),
              Text(
                value.phoneNumber,
                style: AppTextStyles.caption.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (onSelect != null)
          IconButton(
            tooltip: AppStrings.changePatient,
            onPressed: onSelect,
            icon: const Icon(Icons.swap_horiz, size: AppSizes.iconDefault),
          ),
      ],
    );
  }
}
