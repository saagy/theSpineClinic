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

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_profile_header.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_quick_actions.dart';
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
        body:
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
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

class _PatientProfile extends StatelessWidget {
  const _PatientProfile({required this.patient, required this.isDoctor});
  final Patient patient;
  final bool isDoctor;

  @override
  Widget build(BuildContext context) {
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
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              tooltip: AppStrings.editPatient,
              onPressed: () => context.push(
                AppRoutes.editPatient.replaceAll(':id', patient.id),
                extra: patient,
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            PatientProfileHeader(patient: patient),
            _PillTabBar(tabs: tabs),
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
}

/// Pill-indicator TabBar with right-edge fade for smooth overflow.
class _PillTabBar extends StatelessWidget {
  const _PillTabBar({required this.tabs});
  final List<Tab> tabs;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: Stack(
        children: [
          TabBar(
            labelColor: AppColors.textOnPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: AppTextStyles.captionBold,
            unselectedLabelStyle: AppTextStyles.captionMedium,
            indicator: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r24)),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: AppColors.transparent,
            isScrollable: true,
            padding: const EdgeInsets.fromLTRB(
                AppSizes.p16, AppSizes.p4, AppSizes.p32, AppSizes.p4),
            tabs: tabs,
          ),
          // Right-edge fade for natural overflow appearance
          Positioned(
            right: 0, top: 0, bottom: 0,
            child: IgnorePointer(
              child: Container(
                width: AppSizes.p24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [AppColors.surface, AppColors.surface.withAlpha(0)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
