library;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/data/treatment_plan_repository_impl.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_input.dart';
import 'package:spine_clinic_app/features/medical_records/domain/treatment_plan.dart';
import 'package:spine_clinic_app/features/medical_records/domain/treatment_plan_repository.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_programs_providers.dart';

part 'treatment_plan_controller.g.dart';

/// Provides a singleton instance of [TreatmentPlanRepository].
@Riverpod(keepAlive: true)
TreatmentPlanRepository treatmentPlanRepository(Ref ref) {
  return TreatmentPlanRepositoryImpl(
    supabaseService: SupabaseService.instance,
  );
}

/// Mutation controller managing treatment plan creation, updates, and deletion.
///
/// Rule 28 — declared with `keepAlive: true` to prevent premature disposal during in-flight requests.
@Riverpod(keepAlive: true)
class TreatmentPlanController extends _$TreatmentPlanController {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// Verifies current user has senior doctor or super admin role.
  Future<AppException?> _verifySeniorDoctorPermission() async {
    final Staff? user = await ref.read(currentUserProvider.future);
    if (user == null) {
      return const AuthException(
        code: 'auth/unauthorized',
        message: 'Must be logged in to perform this action.',
        userMessageKey: 'error_auth_generic',
      );
    }
    if (!user.isSeniorDoctor) {
      return const AuthException(
        code: 'auth/permission-denied',
        message: 'Only senior doctors and super admins can manage treatment plans.',
        userMessageKey: 'error_permission_denied',
      );
    }
    return null;
  }

  /// Atomically creates or updates a treatment plan.
  Future<Result<TreatmentPlan>> upsertPlan({
    required String programId,
    required String patientId,
    String? planId,
    required String planName,
    required bool isActive,
    String? notes,
    required List<ModalityInput> modalities,
  }) async {
    final permError = await _verifySeniorDoctorPermission();
    if (permError != null) return Result.failure(permError);

    state = const AsyncValue.loading();
    final repo = ref.read(treatmentPlanRepositoryProvider);

    final result = await repo.upsertPlan(
      programId: programId,
      planId: planId,
      planName: planName,
      isActive: isActive,
      notes: notes,
      modalities: modalities,
    );

    if (!ref.mounted) return result;

    result.when(
      success: (plan) {
        state = const AsyncValue.data(null);
        ref.invalidate(programDetailProvider(programId));
        if (ref.exists(patientProgramsProvider(patientId))) {
          ref.read(patientProgramsProvider(patientId).notifier).refresh();
        }
      },
      failure: (e) => state = AsyncValue.error(e, StackTrace.current),
    );

    return result;
  }

  /// Atomically switches the active plan for a program.
  Future<Result<void>> activatePlan({
    required String planId,
    required String programId,
    required String patientId,
  }) async {
    final permError = await _verifySeniorDoctorPermission();
    if (permError != null) return Result.failure(permError);

    state = const AsyncValue.loading();
    final repo = ref.read(treatmentPlanRepositoryProvider);

    final result = await repo.activatePlan(
      planId: planId,
      programId: programId,
    );
    if (!ref.mounted) return result;

    result.when(
      success: (_) {
        state = const AsyncValue.data(null);
        ref.invalidate(programDetailProvider(programId));
        if (ref.exists(patientProgramsProvider(patientId))) {
          ref.read(patientProgramsProvider(patientId).notifier).refresh();
        }
      },
      failure: (e) => state = AsyncValue.error(e, StackTrace.current),
    );

    return result;
  }

  /// Atomically deletes a treatment plan.
  Future<Result<void>> deletePlan({
    required String planId,
    required String programId,
    required String patientId,
  }) async {
    final permError = await _verifySeniorDoctorPermission();
    if (permError != null) return Result.failure(permError);

    state = const AsyncValue.loading();
    final repo = ref.read(treatmentPlanRepositoryProvider);

    final result = await repo.deletePlan(planId);
    if (!ref.mounted) return result;

    result.when(
      success: (_) {
        state = const AsyncValue.data(null);
        ref.invalidate(programDetailProvider(programId));
        if (ref.exists(patientProgramsProvider(patientId))) {
          ref.read(patientProgramsProvider(patientId).notifier).refresh();
        }
      },
      failure: (e) => state = AsyncValue.error(e, StackTrace.current),
    );

    return result;
  }
}
