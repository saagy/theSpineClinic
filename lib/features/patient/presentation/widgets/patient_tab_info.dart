import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';

import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_chip.dart';
import 'package:spine_clinic_app/shared/widgets/info_row.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';

/// Renders the core registration information and doctor assignments of a patient.
class PatientTabInfo extends ConsumerWidget {
  /// Creates a [PatientTabInfo].
  const PatientTabInfo({super.key, required this.patient});

  /// The patient entity.
  final Patient patient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignedDoctorsAsync = ref.watch(patientAssignedDoctorsProvider(patient.id));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            title: AppStrings.patientDetails,
            child: Column(
              children: [
                InfoRow(label: AppStrings.fullName, value: patient.fullName),
                InfoRow(label: AppStrings.phone, value: patient.phoneNumber),
                InfoRow(label: AppStrings.program, value: patient.program ?? 'None'),
                InfoRow(label: AppStrings.clinic, value: patient.clinic.displayLabel),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.p16),
          SectionCard(
            title: AppStrings.assignedDoctors,
            child: assignedDoctorsAsync.when(
              data: (doctors) {
                if (doctors.isEmpty) {
                  return const Text(AppStrings.noDoctorsAssigned);
                }
                return Wrap(
                  spacing: AppSizes.p8,
                  runSpacing: AppSizes.p8,
                  children: doctors
                      .map((doc) => AppChip(label: doc.fullName))
                      .toList(),
                );
              },
              loading: () => const Center(
                child: SizedBox(
                  width: AppSizes.thumbnailDefault,
                  height: AppSizes.thumbnailDefault,
                  child: CircularProgressIndicator(strokeWidth: AppSizes.strokeWidthThin),
                ),
              ),
              error: (_, __) => const Text(AppStrings.errorLoadingAssignedDoctors),
            ),
          ),
          const SizedBox(height: AppSizes.p24),
          AppButton(
            labelText: AppStrings.editPatient,
            onPressed: () {
              context.push(
                AppRoutes.editPatient.replaceAll(':id', patient.id),
                extra: patient,
              );
            },
          ),
        ],
      ),
    );
  }
}
