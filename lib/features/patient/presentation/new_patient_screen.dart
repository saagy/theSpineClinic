import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/new_patient_controller.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/new_patient_form.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/loading_overlay.dart';

/// Screen allowing receptionists and admins to register a new patient.
class NewPatientScreen extends ConsumerWidget {
  /// Creates a [NewPatientScreen].
  const NewPatientScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ── Role Guardrail (doctor blocked) ──
    final asyncUser = ref.watch(currentUserProvider);
    final user = asyncUser.value;

    if (user != null && user.role == UserRole.doctor) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.registerPatient),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        body: const ErrorView(
          exception: DatabaseException(
            code: 'db/rls-violation',
            message: 'Doctors are completely blocked from registering patients.',
            userMessageKey: 'error_database_permission_denied',
          ),
        ),
      );
    }

    final submitState = ref.watch(newPatientControllerProvider);
    final isSaving = submitState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.registerPatient),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: isSaving,
        child: const SingleChildScrollView(
          padding: EdgeInsets.all(AppSizes.p16),
          child: NewPatientForm(),
        ),
      ),
    );
  }
}
