/// Assigned doctors section for the patient info tab.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/shared/widgets/doctor_row.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/eyebrow_label.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

class PatientInfoAssignedDoctorsSection extends StatelessWidget {
  const PatientInfoAssignedDoctorsSection({
    super.key,
    required this.doctorsAsync,
  });

  final AsyncValue<List<Staff>> doctorsAsync;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const EyebrowLabel(text: AppStrings.assignedDoctors),
          const SizedBox(height: AppSizes.p8),
          doctorsAsync.when(
            data: (doctors) => doctors.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
                    child: Text(
                      AppStrings.noDoctorsAssigned,
                      style: AppTextStyles.bodySecondary.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  )
                : Column(
                    children: doctors
                        .map(
                          (doctor) => DoctorRow(
                            name: doctor.fullName,
                            isActive: doctor.isActive,
                          ),
                        )
                        .toList(),
                  ),
            loading: () => const SkeletonListTile(),
            error: (_, __) => ErrorView(
              exception: const UnknownException(
                message: AppStrings.errorLoadingAssignedDoctors,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
