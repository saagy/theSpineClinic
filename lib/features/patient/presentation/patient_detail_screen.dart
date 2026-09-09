import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_appointments.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_documents.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_header.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_notes.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_overview.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_patient_menu.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_payments.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_programs.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_page_skeleton.dart';
import 'package:spine_clinic_app/features/patient/presentation/workspace_refresh.dart';
import 'package:spine_clinic_app/shared/widgets/app_back_button.dart';
import 'package:spine_clinic_app/shared/widgets/record_section.dart';

/// Role-aware patient workspace. Existing repositories own its data.
class PatientDetailScreen extends ConsumerWidget {
  const PatientDetailScreen({super.key, required this.patientId});
  final String patientId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    backgroundColor: Theme.of(context).colorScheme.surface,
    appBar: AppBar(
      leading: const AppBackButton(),
      title: const Text(AppStrings.patientRecord),
      actions: [
        WorkspacePatientEditAction(patientId: patientId),
        WorkspacePatientMenu(patientId: patientId),
      ],
    ),
    body: SafeArea(
      top: false,
      child: RecordAsync(
        skeleton: const WorkspacePageSkeleton(),
        value: ref.watch(canAccessPatientProvider(patientId)),
        onRetry: () => ref.invalidate(canAccessPatientProvider(patientId)),
        data: (allowed) {
          if (!allowed) {
            return const Center(child: RecordMessage(message: AppStrings.errorDatabasePermissionDenied));
          }
          return RecordAsync(
            skeleton: const WorkspacePageSkeleton(),
            value: ref.watch(patientDetailProvider(patientId)),
            onRetry: () => ref.invalidate(patientDetailProvider(patientId)),
            data: (patient) => _Workspace(patient: patient),
          );
        },
      ),
    ),
  );
}

class _Workspace extends ConsumerWidget {
  const _Workspace({required this.patient});
  final Patient patient;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDoctor = ref.watch(currentUserProvider).value?.role == UserRole.doctor;
    final labels = [
      AppStrings.patientOverview,
      AppStrings.programs,
      AppStrings.appointments,
      AppStrings.notes,
      AppStrings.tabDocuments,
      if (!isDoctor) AppStrings.payments,
    ];
    final selected = ref.watch(patientActiveTabProvider(patient.id));
    final index = selected.clamp(0, labels.length - 1);
    void select(int tab) => ref.read(patientActiveTabProvider(patient.id).notifier).setTab(tab);
    void payments() => select(5);

    final Widget content = switch (index) {
      0 => WorkspaceOverview(
        patient: patient,
        isDoctor: isDoctor,
        onPrograms: () => select(1),
        onDocuments: () => select(4),
        onPayments: payments,
      ),
      1 => WorkspacePrograms(patientId: patient.id),
      2 => WorkspaceAppointments(patientId: patient.id),
      3 => WorkspaceNotes(patientId: patient.id),
      4 => WorkspaceDocuments(patientId: patient.id),
      _ => WorkspacePayments(patientId: patient.id),
    };
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: double.infinity),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WorkspaceHeader(patient: patient, isDoctor: isDoctor),
              WorkspaceTabs(patientId: patient.id, labels: labels),
              const Divider(height: AppSizes.borderWidth),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => refreshPatientWorkspace(ref, patient.id),
                  child: ListView(
                    key: PageStorageKey('${patient.id}/$index'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: AppSizes.p8, bottom: AppSizes.p24),
                    children: [content],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
