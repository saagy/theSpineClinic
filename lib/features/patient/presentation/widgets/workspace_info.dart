import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/shared/widgets/record_fact_grid.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_phone_options_sheet.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_monogram_badge.dart';
import 'package:spine_clinic_app/shared/widgets/record_section.dart';

class WorkspaceInfo extends ConsumerWidget {
  const WorkspaceInfo({super.key, required this.patient});
  final Patient patient;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctors = patientAssignedDoctorsProvider(patient.id);
    return RecordSection(
      title: AppStrings.patientDetails,
      child: RecordFactGrid(
        children: [
          // The main phone is the call action in the header.
          if (_text(patient.personalDetails.secondaryPhone) case final String second)
            _PhoneFact(label: AppStrings.patientSecondaryPhone, phone: second),
          if (_text(patient.personalDetails.address) case final String address)
            RecordFact(label: AppStrings.patientAddress, value: address),
          RecordFact(label: AppStrings.registered, value: Formatters.formatDateMedium(patient.createdAt)),
          if (patient.lastAppointmentDate != null)
            RecordFact(
              label: AppStrings.lastVisit,
              value: Formatters.formatDateMedium(patient.lastAppointmentDate!),
            ),
          if (_text(patient.personalDetails.referralSource) case final String source)
            RecordFact(label: AppStrings.patientReferralSource, value: source),
          if (_text(patient.personalDetails.nationality) case final String nationality)
            RecordFact(label: AppStrings.patientNationality, value: nationality),
          RecordAsync(
            value: ref.watch(doctors),
            onRetry: () => ref.invalidate(doctors),
            data: (staff) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.attendingStaff,
                  style: AppTextStyles.caption.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSizes.p8),
                if (staff.isEmpty) const Text(AppStrings.noDoctorsAssigned, style: AppTextStyles.body),
                for (final doctor in staff)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.p4),
                    child: Row(
                      children: [
                        ExcludeSemantics(
                          child: PatientMonogramBadge(name: doctor.fullName, size: AppSizes.p32),
                        ),
                        const SizedBox(width: AppSizes.p8),
                        Expanded(child: Text(doctor.fullName, style: AppTextStyles.bodyMedium)),
                      ],
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

String? _text(String? value) => value == null || value.trim().isEmpty ? null : value;

/// A phone number that opens the call and WhatsApp options.
class _PhoneFact extends StatelessWidget {
  const _PhoneFact({required this.label, required this.phone});
  final String label;
  final String phone;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => PatientPhoneOptionsSheet.show(context, phone),
      borderRadius: BorderRadius.circular(AppSizes.r6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant)),
            const SizedBox(height: AppSizes.p4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.phone_outlined, size: AppSizes.iconSmall, color: colors.primary),
                const SizedBox(width: AppSizes.p6),
                Flexible(
                  child: Text(
                    Formatters.formatPhone(phone),
                    style: AppTextStyles.bodyMedium.copyWith(color: colors.primary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Session balances are read-only: invoices, refunds and visits change them.
class WorkspaceBalances extends StatelessWidget {
  const WorkspaceBalances({super.key, required this.patient});
  final Patient patient;
  @override
  Widget build(BuildContext context) {
    return RecordSection(
      title: AppStrings.availableSessions,
      child: RecordFactGrid(
        children: [
          _balance(context, AppStrings.sessionBalance, patient.sessionBalance),
          _balance(context, AppStrings.tractionBalance, patient.tractionBalance),
          Text(
            AppStrings.patientBalanceContext,
            style: AppTextStyles.caption.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _balance(BuildContext context, String label, int balance) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
    child: Row(
      children: [
        Expanded(child: Text(label, style: AppTextStyles.body)),
        Text(
          '$balance',
          style: AppTextStyles.headingMedium.copyWith(
            color: balance < 0 ? Theme.of(context).colorScheme.error : null,
          ),
        ),
      ],
    ),
  );
}
