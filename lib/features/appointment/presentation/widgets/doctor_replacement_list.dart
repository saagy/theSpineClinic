import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/doctor_replacement_appointment_row.dart';

/// Scrollable list of selectable appointments for doctor replacement.
class DoctorReplacementList extends StatelessWidget {
  const DoctorReplacementList({
    super.key,
    required this.appointments,
    required this.selectedIds,
    required this.onToggle,
  });

  final List<AppointmentWithPatient> appointments;
  final Set<String> selectedIds;
  final void Function(String id, bool selected) onToggle;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
      itemCount: appointments.length,
      itemBuilder: (_, index) {
        final item = appointments[index];
        return DoctorReplacementAppointmentRow(
          item: item,
          selected: selectedIds.contains(item.appointment.id),
          onChanged: (selected) => onToggle(item.appointment.id, selected),
        );
      },
    );
  }
}
