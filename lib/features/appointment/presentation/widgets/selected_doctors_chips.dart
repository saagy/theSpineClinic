library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/shared/widgets/app_chip.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';

/// A stateless wrap that displays the list of pre-selected doctors as [AppChip]s.
class SelectedDoctorsChips extends StatelessWidget {
  /// Creates a [SelectedDoctorsChips] widget.
  const SelectedDoctorsChips({
    super.key,
    required this.doctors,
    required this.onRemoveDoctor,
  });

  /// The list of pre-selected doctors.
  final List<Staff> doctors;

  /// Callback when a doctor chip is deleted.
  final ValueChanged<Staff> onRemoveDoctor;

  @override
  Widget build(BuildContext context) {
    if (doctors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: AppSizes.p8,
      runSpacing: AppSizes.p8,
      children: doctors.map((doctor) {
        return AppChip(
          label: doctor.fullName,
          onDeleted: () => onRemoveDoctor(doctor),
        );
      }).toList(),
    );
  }
}
