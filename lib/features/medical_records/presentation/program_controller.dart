library;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_repository.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_status.dart';
import 'package:spine_clinic_app/features/medical_records/domain/treatment_plan_input.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_programs_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import 'program_mutation_state.dart';

part 'program_controller.g.dart';
part 'program_save_actions.dart';

/// Mutation controller managing program creation, updates, status changes, and deletion (Rule 28).
@Riverpod(keepAlive: true)
class ProgramController extends _$ProgramController with _ProgramSaveActions {
  @override
  ProgramMutationState build() => const ProgramMutationState();

  /// Verifies current user has senior doctor or super admin role.
  @override
  AppException? _verifySeniorDoctorPermission() {
    final Staff? user = ref.read(currentUserProvider).value;
    if (user == null) {
      return const AuthException(
        code: 'auth/unauthorized',
        message: 'Must be logged in to perform this action.',
        userMessageKey: 'error_auth_generic',
      );
    }
    if (!user.isActive || !user.isSeniorDoctor) {
      return const AuthException(
        code: 'auth/permission-denied',
        message: 'Only senior doctors and super admins can perform this action.',
        userMessageKey: 'error_permission_denied',
      );
    }
    return null;
  }

  /// Updates program status (e.g. active, completed, archived).
  Future<Result<void>> updateStatus({
    required String programId,
    required String patientId,
    required ProgramStatus status,
  }) async {
    final permError = _verifySeniorDoctorPermission();
    if (permError != null) return Result.failure(permError);

    state = state.copyWith(isLoading: true, clearError: true, scope: 'program:$programId');
    final repo = ref.read(programRepositoryProvider);

    final result = await repo.updateProgramStatus(programId: programId, status: status);

    if (!ref.mounted) return result;

    result.when(
      success: (_) {
        state = state.copyWith(isLoading: false, clearError: true);
        ref.read(patientProgramsProvider(patientId).notifier).refresh();
        ref.invalidate(programDetailProvider(programId));
      },
      failure: (e) => state = state.copyWith(isLoading: false, error: e),
    );

    return result;
  }

  /// Deletes a program.
  Future<Result<void>> deleteProgram({required String programId, required String patientId}) async {
    final permError = _verifySeniorDoctorPermission();
    if (permError != null) return Result.failure(permError);

    state = state.copyWith(isLoading: true, clearError: true, scope: 'program:$programId');
    final repo = ref.read(programRepositoryProvider);

    final result = await repo.deleteProgram(programId);
    if (!ref.mounted) return result;

    result.when(
      success: (_) {
        state = state.copyWith(isLoading: false, clearError: true);
        ref.read(patientProgramsProvider(patientId).notifier).removeProgram(programId);
        ref.invalidate(patientDocumentsNotifierProvider(patientId));
      },
      failure: (e) => state = state.copyWith(isLoading: false, error: e),
    );

    return result;
  }
}
