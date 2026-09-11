import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_due.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_follow_up.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_info.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_medical_history.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_programs.dart';

/// Streamlined clinical overview tab.
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
    final programs = Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.p16),
      child: WorkspacePrograms(patientId: patient.id, overview: true, onViewAll: onPrograms),
    );
    final history = WorkspaceMedicalHistory(patientId: patient.id);
    final followUp = Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.p16),
      child: WorkspaceFollowUp(patient: patient),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = MediaQuery.sizeOf(context).width < AppSizes.patientWorkspaceBreakpoint;
        final info = isMobile ? WorkspaceInfo(patient: patient) : const SizedBox.shrink();
        final balances = isMobile ? WorkspaceBalances(patient: patient) : const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isDoctor) WorkspaceDue(patientId: patient.id, onOpen: onPayments),
            followUp,
            programs,
            if (isMobile) balances,
            history,
            if (isMobile) info,
          ],
        );
      },
    );
  }
}
