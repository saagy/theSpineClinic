import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/shared/widgets/record_fact_grid.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_phone_options_sheet.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/package_balance_edit_dialog.dart';
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
          TextButton.icon(
            onPressed: () => PatientPhoneOptionsSheet.show(context, patient.phoneNumber),
            icon: const Icon(Icons.phone_outlined, size: AppSizes.iconSmall),
            label: Text(Formatters.formatPhone(patient.phoneNumber), style: AppTextStyles.bodyMedium),
          ),
          RecordFact(label: AppStrings.clinic, value: patient.clinic.displayLabel),
          RecordFact(label: AppStrings.registered, value: Formatters.formatDateMedium(patient.createdAt)),
          if (patient.lastAppointmentDate != null)
            RecordFact(
              label: AppStrings.lastVisit,
              value: Formatters.formatDateMedium(patient.lastAppointmentDate!),
            ),
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

class WorkspaceBalances extends ConsumerWidget {
  const WorkspaceBalances({super.key, required this.patient});
  final Patient patient;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    return RecordSection(
      title: AppStrings.availableSessions,
      action: user != null && user.role != UserRole.doctor ? AppStrings.edit : null,
      onAction: () {
        final user = ref.read(currentUserProvider).value;
        if (user == null || user.role == UserRole.doctor) return;
        showDialog<void>(
          context: context,
          builder: (_) => PackageBalanceEditDialog(patient: patient),
        );
      },
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
