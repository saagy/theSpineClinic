library;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/medical_records/data/program_repository_impl.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_repository.dart';

part 'patient_programs_providers.g.dart';

/// Provides a singleton instance of [ProgramRepository].
@Riverpod(keepAlive: true)
ProgramRepository programRepository(Ref ref) {
  return ProgramRepositoryImpl(supabaseService: SupabaseService.instance);
}

/// Manages and caches the list of rehabilitation programs for a patient.
@riverpod
class PatientProgramsNotifier extends _$PatientProgramsNotifier {
  @override
  FutureOr<List<PatientProgram>> build(String patientId) async {
    final ProgramRepository repo = ref.watch(programRepositoryProvider);
    final Result<List<PatientProgram>> result =
        await repo.getProgramsForPatient(patientId);
    return result.when(
      success: (List<PatientProgram> data) => data,
      failure: (AppException exception) => throw exception,
    );
  }

  /// Updates or inserts a program in place without reloading the list.
  void addOrUpdateProgram(PatientProgram program) {
    if (!state.hasValue) {
      state = AsyncValue.data([program]);
      return;
    }

    final current = state.value!;
    final index = current.indexWhere((p) => p.id == program.id);
    if (index >= 0) {
      final updated = List<PatientProgram>.from(current);
      updated[index] = program;
      state = AsyncValue.data(updated);
    } else {
      state = AsyncValue.data([program, ...current]);
    }
  }

  /// Removes a deleted program in place.
  void removeProgram(String programId) {
    if (!state.hasValue) return;
    final filtered = state.value!.where((p) => p.id != programId).toList();
    state = AsyncValue.data(filtered);
  }

  /// Silently refreshes programs from the server.
  Future<void> refresh() async {
    final ProgramRepository repo = ref.read(programRepositoryProvider);
    final Result<List<PatientProgram>> result =
        await repo.getProgramsForPatient(patientId);
    if (!ref.mounted) return;
    result.when(
      success: (List<PatientProgram> data) {
        state = AsyncValue.data(data);
      },
      failure: (AppException exception) {
        if (!state.hasValue) {
          state = AsyncValue.error(exception, StackTrace.current);
        }
      },
    );
  }
}

/// Fetches a single program detail by [programId].
@riverpod
FutureOr<PatientProgram?> programDetail(Ref ref, String programId) async {
  final ProgramRepository repo = ref.watch(programRepositoryProvider);
  final Result<PatientProgram?> result = await repo.getProgramById(programId);
  return result.when(
    success: (PatientProgram? data) => data,
    failure: (AppException exception) => throw exception,
  );
}
