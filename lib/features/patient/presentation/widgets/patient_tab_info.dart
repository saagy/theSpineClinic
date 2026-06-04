import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
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
    final user = ref.watch(currentUserProvider).value;
    final isDoctor = user?.role == UserRole.doctor;

    // Assigned doctors are currently mocked.
    final List<String> mockDoctors = ['Dr. Hassan Aly', 'Dr. Khaled Amin'];

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
                // DOB, Gender, and Blood Type are stubs pending DB updates.
                const InfoRow(label: 'Date of Birth', value: '1985-05-12'),
                const InfoRow(label: 'Gender', value: 'Male'),
                const InfoRow(label: 'Blood Type', value: 'O+'),
                InfoRow(label: AppStrings.program, value: patient.program ?? 'None'),
                InfoRow(label: AppStrings.clinic, value: patient.clinic.displayLabel),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.p16),
          SectionCard(
            title: AppStrings.assignedDoctors,
            child: mockDoctors.isEmpty
                ? const Text('No doctors assigned')
                : Wrap(
                    spacing: AppSizes.p8,
                    runSpacing: AppSizes.p8,
                    children: mockDoctors
                        .map((doc) => AppChip(label: doc))
                        .toList(),
                  ),
          ),
          if (!isDoctor) ...[
            const SizedBox(height: AppSizes.p24),
            AppButton(
              labelText: AppStrings.editPatient,
              onPressed: () {
                // To be wired to EditPatientScreen in a future phase.
              },
            ),
          ],
        ],
      ),
    );
  }
}
