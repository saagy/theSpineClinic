/// Patient profile screen with rich header, pill TabBar, and FAB
/// quick-actions hub.
///
/// Sub-tabs: Info | Appointments | Records | Payments | Documents
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
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
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

/// Top-level patient profile with header, tabs, and quick-action FAB.
class PatientDetailScreen extends ConsumerWidget {
  const PatientDetailScreen({super.key, required this.patientId});
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPatient = ref.watch(patientDetailProvider(patientId));
    final user = ref.watch(currentUserProvider).value;
    final isDoctor = user?.role == UserRole.doctor;

    return asyncPatient.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: PatientProfileSkeleton(),
      ),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: const AppBackButton(),
      ),
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
    final tabs = <Tab>[
      const Tab(text: 'Info'),
      const Tab(text: 'Appointments'),
      const Tab(text: 'Records'),
      if (!isDoctor) const Tab(text: 'Payments'),
      const Tab(text: 'Documents'),
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
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          leading: const AppBackButton(),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSizes.p16),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary.withAlpha(25),
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.p12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.r12),
                  ),
                ),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => context.push(
                  AppRoutes.editPatient.replaceAll(':id', patient.id),
                  extra: patient,
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            PatientProfileHeader(patient: patient, isDoctor: isDoctor),
            PillTabBar(tabs: tabs),
            Expanded(child: TabBarView(children: views)),
          ],
        )
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.04, end: 0, duration: 400.ms, curve: Curves.easeOut),
        floatingActionButton: PatientQuickActionsFab(
          patient: patient,
          isDoctor: isDoctor,
        ),
      ),
    );
  }
}
