/// Patient profile screen with rich header, pill TabBar, and FAB
/// quick-actions hub.
///
/// Sub-tabs: Info | Appointments | Records | Payments | Documents
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/delete_patient_controller.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_profile_header.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_profile_skeleton.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_quick_actions.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/pill_tab_bar.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_tab_appointments.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_tab_documents.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_tab_info.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_tab_payments.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_tab_records.dart';
import 'package:spine_clinic_app/shared/widgets/app_back_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

class PatientDetailScreen extends ConsumerWidget {
  const PatientDetailScreen({super.key, required this.patientId});
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPatient = ref.watch(patientDetailProvider(patientId));
    final user = ref.watch(currentUserProvider).value;
    final isDoctor = user?.role == UserRole.doctor;

    return asyncPatient.when(
      loading: () => const Scaffold(body: PatientProfileSkeleton()),
      error: (error, _) => _ErrorScaffold(
        error: error,
        onRetry: () => ref.invalidate(patientDetailProvider(patientId)),
      ),
      data: (patient) => _PatientProfile(patient: patient, isDoctor: isDoctor),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final AppException ex = error is AppException
        ? error as AppException
        : UnknownException(message: AppStrings.errorDatabaseQueryFailed);
    return Scaffold(
      appBar: AppBar(leading: const AppBackButton()),
      body: ErrorView(exception: ex, onRetry: onRetry),
    );
  }
}

class _PatientProfile extends ConsumerWidget {
  const _PatientProfile({required this.patient, required this.isDoctor});
  final Patient patient;
  final bool isDoctor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final user = ref.watch(currentUserProvider).value;
    final canDelete = user?.role == UserRole.superAdmin ||
        user?.role == UserRole.receptionist;
    final isEmptyAsync = ref.watch(patientIsEmptyProvider(patient.id));
    final bool patientIsEmpty = isEmptyAsync.value ?? false;

    final tabs = <Tab>[
      const Tab(text: AppStrings.tabInfo),
      const Tab(text: AppStrings.appointments),
      const Tab(text: AppStrings.tabRecords),
      if (!isDoctor) const Tab(text: AppStrings.payments),
      const Tab(text: AppStrings.tabDocuments),
    ];
    final views = <Widget>[
      PatientTabInfo(patient: patient),
      PatientTabAppointments(patient: patient),
      PatientTabRecords(patient: patient),
      if (!isDoctor) PatientTabPayments(patient: patient),
      PatientTabDocuments(patient: patient),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: Text(
            patient.fullName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: AppStrings.edit,
              onPressed: () => context.push(
                AppRoutes.editPatient.replaceAll(':id', patient.id),
                extra: patient,
              ),
            ),
            if (canDelete && patientIsEmpty)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.r12),
                ),
                onSelected: (_) => _confirmDelete(context, ref),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: cs.error),
                        const SizedBox(width: AppSizes.p12),
                        Text(AppStrings.deletePatient),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        body: Column(
          children: [
            PatientProfileHeader(patient: patient, isDoctor: isDoctor),
            PillTabBar(tabs: tabs),
            Expanded(child: TabBarView(children: views)),
          ],
        ),
        floatingActionButton: PatientQuickActionsFab(
          patient: patient,
          isDoctor: isDoctor,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmationDialog(
        title: AppStrings.deletePatient,
        message: AppStrings.deletePatientWarning,
        isDestructive: true,
      ),
    );
    if (confirm != true || !context.mounted) return;
    final result = await ref
        .read(deletePatientControllerProvider.notifier)
        .deletePatient(patient.id);
    if (!context.mounted) return;
    result.when(
      success: (_) {
        AppSnackbar.show(context,
            message: AppStrings.patientDeleted,
            variant: AppSnackbarVariant.success);
        context.pop();
      },
      failure: (e) => AppSnackbar.show(context,
          message: AppStrings.fromKey(e.userMessageKey),
          variant: AppSnackbarVariant.error),
    );
  }
}
