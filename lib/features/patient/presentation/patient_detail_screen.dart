/// Patient profile screen with scroll-away header, pinned pill TabBar,
/// and access control guard.
///
/// Sub-tabs: Info | Appointments | Records | Payments | Documents
///
/// Rule 1 — keep files under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/error_scaffold.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_profile.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_profile_skeleton.dart';

class PatientDetailScreen extends ConsumerWidget {
  const PatientDetailScreen({super.key, required this.patientId});
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canAccessAsync = ref.watch(canAccessPatientProvider(patientId));
    final asyncPatient = ref.watch(patientDetailProvider(patientId));
    final user = ref.watch(currentUserProvider).value;
    final isDoctor = user?.role == UserRole.doctor;

    final Widget content = canAccessAsync.when(
      loading: () => const KeyedSubtree(
        key: ValueKey('patient_detail_loading'),
        child: Scaffold(body: PatientProfileSkeleton()),
      ),
      error: (error, _) => KeyedSubtree(
        key: const ValueKey('patient_detail_error'),
        child: PatientErrorScaffold(
          error: error,
          onRetry: () {
            ref.invalidate(canAccessPatientProvider(patientId));
            ref.invalidate(patientDetailProvider(patientId));
          },
        ),
      ),
      data: (canAccess) {
        if (!canAccess) {
          return KeyedSubtree(
            key: const ValueKey('patient_detail_forbidden'),
            child: PatientErrorScaffold(
              error: const DatabaseException(
                code: 'db/permission-denied',
                message: 'Doctor does not have access to this patient',
                userMessageKey: 'error_database_permission_denied',
              ),
              onRetry: () {
                ref.invalidate(canAccessPatientProvider(patientId));
                ref.invalidate(patientDetailProvider(patientId));
              },
            ),
          );
        }

        return asyncPatient.when(
          loading: () => const KeyedSubtree(
            key: ValueKey('patient_detail_loading'),
            child: Scaffold(body: PatientProfileSkeleton()),
          ),
          error: (error, _) => KeyedSubtree(
            key: const ValueKey('patient_detail_error'),
            child: PatientErrorScaffold(
              error: error,
              onRetry: () => ref.invalidate(patientDetailProvider(patientId)),
            ),
          ),
          data: (patient) => KeyedSubtree(
            key: ValueKey('patient_detail_data_${patient.id}'),
            child: PatientProfile(patient: patient, isDoctor: isDoctor),
          ),
        );
      },
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: content,
    );
  }
}
