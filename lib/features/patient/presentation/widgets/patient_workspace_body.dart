import 'package:flutter/material.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_tabs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_workspace_tab.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_summary_sidebar.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_appointments.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_documents.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_header.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_notes.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_overview.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/patient_invoices_tab.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_programs.dart';
import 'package:spine_clinic_app/features/patient/presentation/workspace_refresh.dart';

/// Body coordinator for the patient workspace supporting desktop side rail and mobile nested scroll.
class PatientWorkspaceBody extends ConsumerWidget {
  const PatientWorkspaceBody({super.key, required this.patient, required this.onScroll});
  final Patient patient;
  final ValueChanged<ScrollNotification> onScroll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserProvider).value?.role;
    final isDoctor = role == UserRole.doctor;
    final tabs = PatientWorkspaceTab.forRole(role);
    final labels = [for (final tab in tabs) tab.label];
    final selected = ref.watch(patientActiveTabProvider(patient.id));
    final index = selected.clamp(0, labels.length - 1);
    void select(PatientWorkspaceTab tab) =>
        ref.read(patientActiveTabProvider(patient.id).notifier).setTab(tabs.indexOf(tab));

    final Widget content = switch (tabs[index]) {
      PatientWorkspaceTab.overview => WorkspaceOverview(
        patient: patient,
        isDoctor: isDoctor,
        onPrograms: () => select(PatientWorkspaceTab.programs),
        onDocuments: () => select(PatientWorkspaceTab.documents),
        onPayments: () => select(PatientWorkspaceTab.payments),
      ),
      PatientWorkspaceTab.programs => WorkspacePrograms(patientId: patient.id),
      PatientWorkspaceTab.appointments => WorkspaceAppointments(patientId: patient.id),
      PatientWorkspaceTab.notes => WorkspaceNotes(patientId: patient.id),
      PatientWorkspaceTab.documents => WorkspaceDocuments(patientId: patient.id),
      PatientWorkspaceTab.payments => PatientInvoicesTab(patient: patient),
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
                      padding: const EdgeInsets.fromLTRB(
                        AppSizes.p24,
                        AppSizes.p12,
                        AppSizes.p24,
                        0,
                      ),
                      child: WorkspaceTabs(patientId: patient.id, labels: labels),
                    ),
                    const Divider(height: AppSizes.borderWidth),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => refreshPatientWorkspace(ref, patient.id),
                        child: ListView(
                          key: PageStorageKey('${patient.id}/$index'),
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.p24,
                            vertical: AppSizes.p16,
                          ),
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: AppSizes.clinicalContentMaxWidth,
                              ),
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
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                sliver: SliverPersistentHeader(
                  pinned: true,
                  delegate: WorkspaceTabsDelegate(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
                      child: WorkspaceTabs(patientId: patient.id, labels: labels),
                    ),
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  ),
                ),
              ),
            ],
            body: RefreshIndicator(
              onRefresh: () => refreshPatientWorkspace(ref, patient.id),
              child: Builder(
                builder: (context) => CustomScrollView(
                  key: PageStorageKey('${patient.id}/$index'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverOverlapInjector(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSizes.p16,
                        AppSizes.p12,
                        AppSizes.p16,
                        AppSizes.p24,
                      ),
                      sliver: SliverToBoxAdapter(child: content),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
