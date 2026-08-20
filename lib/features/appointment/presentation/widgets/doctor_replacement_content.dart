import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/doctor_replacement_header.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/doctor_replacement_list.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';

/// Loaded data view for the doctor replacement workflow.
class DoctorReplacementContent extends StatelessWidget {
  const DoctorReplacementContent({
    super.key,
    required this.day,
    required this.appointments,
    required this.appointmentIds,
    required this.selectedDoctor,
    required this.isSubmitting,
    required this.onChooseDoctor,
    required this.onSelectAllChanged,
    required this.onToggleAppointment,
    required this.onSubmit,
  });

  final DateTime day;
  final List<AppointmentWithPatient> appointments;
  final Set<String> appointmentIds;
  final Staff? selectedDoctor;
  final bool isSubmitting;
  final VoidCallback onChooseDoctor;
  final ValueChanged<bool?> onSelectAllChanged;
  final void Function(String id, bool selected) onToggleAppointment;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final bool allSelected =
        appointmentIds.length == appointments.length && appointments.isNotEmpty;

    return Column(
      children: [
        DoctorReplacementHeader(
          day: day,
          totalAppointments: appointments.length,
          selectedCount: appointmentIds.length,
          selectedDoctor: selectedDoctor,
          allSelected: allSelected,
          onChooseDoctor: onChooseDoctor,
          onSelectAllChanged: onSelectAllChanged,
        ),
        Expanded(
          child: DoctorReplacementList(
            appointments: appointments,
            selectedIds: appointmentIds,
            onToggle: onToggleAppointment,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: AppButton(
            labelText: AppStrings.replaceOnAppointments(appointmentIds.length),
            isLoading: isSubmitting,
            onPressed: selectedDoctor == null || appointmentIds.isEmpty
                ? null
                : onSubmit,
          ),
        ),
      ],
    );
  }
}
