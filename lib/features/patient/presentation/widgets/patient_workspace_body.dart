import 'package:flutter/material.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_tabs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_summary_sidebar.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_appointments.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_documents.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_header.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_notes.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_overview.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_payments.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_programs.dart';
import 'package:spine_clinic_app/features/patient/presentation/workspace_refresh.dart';

/// Body coordinator for the patient workspace supporting desktop side rail and mobile nested scroll.
class PatientWorkspaceBody extends ConsumerWidget {
  const PatientWorkspaceBody({super.key, required this.patient, required this.onScroll});
  final Patient patient;
  final ValueChanged<ScrollNotification> onScroll;

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= AppSizes.patientWorkspaceBreakpoint;
        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PatientSummarySidebar(patient: patient, isDoctor: isDoctor),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSizes.p24, AppSizes.p12, AppSizes.p24, 0),
                      child: WorkspaceTabs(patientId: patient.id, labels: labels),
                    ),
                    const Divider(height: AppSizes.borderWidth),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => refreshPatientWorkspace(ref, patient.id),
                        child: ListView(
                          key: PageStorageKey('${patient.id}/$index'),
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24, vertical: AppSizes.p16),
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: AppSizes.clinicalContentMaxWidth),
                              child: content,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            onScroll(notification);
            return false;
          },
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: WorkspaceHeader(patient: patient, isDoctor: isDoctor),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: WorkspaceTabsDelegate(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
                    child: WorkspaceTabs(patientId: patient.id, labels: labels),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                ),
              ),
            ],
            body: RefreshIndicator(
              onRefresh: () => refreshPatientWorkspace(ref, patient.id),
              child: ListView(
                key: PageStorageKey('${patient.id}/$index'),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(AppSizes.p16, AppSizes.p12, AppSizes.p16, AppSizes.p24),
                children: [content],
              ),
            ),
          ),
        );
      },
    );
  }
}
