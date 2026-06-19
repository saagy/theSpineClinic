import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_avatar.dart';
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

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(patientDetailProvider(patient.id));
        ref.invalidate(patientAssignedDoctorsProvider(patient.id));
        try {
          await ref.read(patientDetailProvider(patient.id).future);
          await ref.read(patientAssignedDoctorsProvider(patient.id).future);
        } catch (_) {
          // Keep the refresh indicator happy if request fails
        }
      },
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
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
                  return Column(
                    children: doctors.map((doc) => _buildDoctorRow(doc)).toList(),
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
          ],
        ),
      ),
    );
  }
}

/// Builds a single doctor row with avatar, name, and optional inactive badge.
///
/// Mirrors the visual design of [AppointmentDoctorsSection._buildActiveDoctorRow]
/// for consistency across Patient Detail and Appointment Detail screens.
Widget _buildDoctorRow(Staff doc) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSizes.p6),
    child: Row(
      children: [
        AppAvatar(name: doc.fullName, radius: 18),
        const SizedBox(width: AppSizes.p8),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  doc.fullName,
                  style: AppTextStyles.bodyBold,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!doc.isActive) ...[
                const SizedBox(width: AppSizes.p6),
                Text(
                  AppStrings.deactivated,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
