import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/shared/widgets/record_section.dart';

import 'package:spine_clinic_app/features/patient/domain/patient.dart';

import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_due.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_follow_up.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_info.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_medical_history.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_programs.dart';

class WorkspaceOverview extends StatelessWidget {
  const WorkspaceOverview({
    super.key,
    required this.patient,
    required this.isDoctor,
    required this.onPrograms,
    required this.onDocuments,
    required this.onPayments,
  });
  final Patient patient;
  final bool isDoctor;
  final VoidCallback onPrograms;
  final VoidCallback onDocuments;
  final VoidCallback onPayments;
  @override
  Widget build(BuildContext context) {
    final programs = WorkspacePrograms(patientId: patient.id, overview: true, onViewAll: onPrograms);
    final history = WorkspaceMedicalHistory(patientId: patient.id);
    final info = WorkspaceInfo(patient: patient);
    final balances = WorkspaceBalances(patient: patient);

    final followUp = RecordSection(
      title: AppStrings.patientVisits,
      child: WorkspaceFollowUp(patient: patient),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isDoctor) WorkspaceDue(patientId: patient.id, onOpen: onPayments),
        if (isDoctor) ...[
          programs,
          history,
          followUp,
          balances,
          info,
        ] else ...[
          info,
          followUp,
          programs,
          balances,
          history,
        ],
      ],
    );
  }
}
