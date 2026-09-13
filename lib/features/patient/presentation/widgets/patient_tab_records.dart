import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_notes.dart';

/// Legacy entry point shares the current workspace controls and behavior.
class PatientTabRecords extends StatelessWidget {
  const PatientTabRecords({super.key, required this.patient});
  final Patient patient;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(AppSizes.p16),
    child: WorkspaceNotes(patientId: patient.id),
  );
}
