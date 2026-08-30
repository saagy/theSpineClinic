library;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_repository.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_status.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_programs_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';

part 'program_controller.g.dart';

/// Mutation controller managing program creation, updates, status changes, and deletion.
///
/// Rule 28 — declared with `keepAlive: true` to prevent premature disposal during in-flight requests.
@Riverpod(keepAlive: true)
class ProgramController extends _$ProgramController {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// Verifies current user has senior doctor or super admin role.
  AppException? _verifySeniorDoctorPermission() {
    final Staff? user = ref.read(currentUserProvider).value;
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
        message: 'Only senior doctors and super admins can perform this action.',
        userMessageKey: 'error_permission_denied',
      );
    }
    return null;
  }

  /// Creates a new patient program atomically.
  Future<Result<PatientProgram>> createProgram({
    required String patientId,
    required List<String> conditionIds,
    String? examination,
    String? imagingNotes,
    String? exaggeratingPositions,
    String? relievingPositions,
    String? notes,
    List<ProgramAttachment>? pendingAttachments,
  }) async {
    final permError = _verifySeniorDoctorPermission();
    if (permError != null) return Result.failure(permError);

    state = const AsyncValue.loading();
    final repo = ref.read(programRepositoryProvider);

    final result = await repo.createProgram(
      patientId: patientId,
      conditionIds: conditionIds,
      examination: examination,
      imagingNotes: imagingNotes,
      exaggeratingPositions: exaggeratingPositions,
      relievingPositions: relievingPositions,
      notes: notes,
      pendingAttachments: pendingAttachments,
    );

    if (!ref.mounted) return result;

    result.when(
      success: (program) {
        state = const AsyncValue.data(null);
        ref.read(patientProgramsProvider(patientId).notifier).addOrUpdateProgram(program);
        if (pendingAttachments != null && pendingAttachments.isNotEmpty) {
          ref.invalidate(patientDocumentsNotifierProvider(patientId));
        }
      },
      failure: (e) => state = AsyncValue.error(e, StackTrace.current),
    );

    return result;
  }

  /// Updates an existing patient program atomically.
  Future<Result<PatientProgram>> updateProgram({
    required String programId,
    required String patientId,
    required List<String> conditionIds,
    String? examination,
    String? imagingNotes,
    String? exaggeratingPositions,
    String? relievingPositions,
    String? notes,
    ProgramStatus? status,
    List<ProgramAttachment>? pendingAttachments,
  }) async {
    final permError = _verifySeniorDoctorPermission();
    if (permError != null) return Result.failure(permError);

    state = const AsyncValue.loading();
    final repo = ref.read(programRepositoryProvider);

    final result = await repo.updateProgram(
      programId: programId,
      patientId: patientId,
      conditionIds: conditionIds,
      examination: examination,
      imagingNotes: imagingNotes,
      exaggeratingPositions: exaggeratingPositions,
      relievingPositions: relievingPositions,
      notes: notes,
      status: status,
      pendingAttachments: pendingAttachments,
    );

    if (!ref.mounted) return result;

    result.when(
      success: (program) {
        state = const AsyncValue.data(null);
        ref.read(patientProgramsProvider(patientId).notifier).addOrUpdateProgram(program);
        ref.invalidate(programDetailProvider(programId));
        if (pendingAttachments != null && pendingAttachments.isNotEmpty) {
          ref.invalidate(patientDocumentsNotifierProvider(patientId));
        }
      },
      failure: (e) => state = AsyncValue.error(e, StackTrace.current),
    );

    return result;
  }

  /// Updates program status (e.g. active, completed, archived).
  Future<Result<void>> updateStatus({
    required String programId,
    required String patientId,
    required ProgramStatus status,
  }) async {
    final permError = _verifySeniorDoctorPermission();
    if (permError != null) return Result.failure(permError);

    state = const AsyncValue.loading();
    final ProgramRepository repo = ref.read(programRepositoryProvider);

    final Result<void> result = await repo.updateProgramStatus(
      programId: programId,
      status: status,
    );

    if (!ref.mounted) return result;

    result.when(
      success: (_) {
        state = const AsyncValue.data(null);
        ref.read(patientProgramsProvider(patientId).notifier).refresh();
        ref.invalidate(programDetailProvider(programId));
      },
      failure: (AppException exception) {
        state = AsyncValue.error(exception, StackTrace.current);
      },
    );

    return result;
  }

  /// Deletes a program.
  Future<Result<void>> deleteProgram({
    required String programId,
    required String patientId,
  }) async {
    final permError = _verifySeniorDoctorPermission();
    if (permError != null) return Result.failure(permError);

    state = const AsyncValue.loading();
    final repo = ref.read(programRepositoryProvider);

    final result = await repo.deleteProgram(programId);
    if (!ref.mounted) return result;

    result.when(
      success: (_) {
        state = const AsyncValue.data(null);
        ref.read(patientProgramsProvider(patientId).notifier).removeProgram(programId);
        ref.invalidate(patientDocumentsNotifierProvider(patientId));
      },
      failure: (e) => state = AsyncValue.error(e, StackTrace.current),
    );

    return result;
  }
}
