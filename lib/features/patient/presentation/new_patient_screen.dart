import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    if (user != null && user.role == UserRole.doctor && !user.isSeniorDoctor) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.registerPatient),
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          elevation: 0,
        ),
        body: const ErrorView(
          exception: DatabaseException(
            code: 'db/rls-violation',
            message: 'Regular doctors are blocked from registering patients.',
            userMessageKey: 'error_database_permission_denied',
          ),
        ),
      );
    }

    final submitState = ref.watch(newPatientControllerProvider);
    final isSaving = submitState.isLoading;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(AppStrings.registerPatient),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: isSaving,
        child: const SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.all(AppSizes.p16),
          child: NewPatientForm(),
        ),
      ),
    );
  }
}
