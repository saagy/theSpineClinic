library;

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/medical_records/data/program_storage_helper.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_repository.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_status.dart';
import 'package:spine_clinic_app/features/medical_records/domain/treatment_plan_input.dart';
import 'package:spine_clinic_app/features/patient/data/patient_document_storage.dart';

/// Supabase-backed implementation of [ProgramRepository].
class ProgramRepositoryImpl implements ProgramRepository {
  ProgramRepositoryImpl({required SupabaseService supabaseService})
      : _service = supabaseService;

  final SupabaseService _service;
  static const String _tableName = 'patient_programs';
  static const String _selectQuery = '''
    *,
    program_conditions(
      id,
      program_id,
      condition_id,
      condition_catalog(*)
    ),
    treatment_plans(
      *,
      plan_modalities(
        *,
        modality_regions(*)
      )
    )
  ''';

  @override
  Future<Result<List<PatientProgram>>> getProgramsForPatient(
    String patientId,
  ) async {
    try {
      final data = await _service.guardQuery(
        () => _service
            .from(_tableName)
            .select(_selectQuery)
            .eq('patient_id', patientId)
            .order('created_at', ascending: false),
      );

      final list = (data as List<dynamic>)
          .map((item) => PatientProgram.fromJson(item as Map<String, dynamic>))
          .toList();

      return Result.success(list);
    } on Exception catch (error) {
      return Result.failure(
        error is AppException ? error : AppException.fromSupabaseException(error),
      );
    }
  }

  @override
  Future<Result<PatientProgram?>> getProgramById(String programId) async {
    try {
      final data = await _service.guardQuery(
        () => _service
            .from(_tableName)
            .select(_selectQuery)
            .eq('id', programId)
            .maybeSingle(),
      );

      if (data == null) return const Result.success(null);
      return Result.success(PatientProgram.fromJson(data));
    } on Exception catch (error) {
      return Result.failure(
        error is AppException ? error : AppException.fromSupabaseException(error),
      );
    }
  }

  @override
  Future<Result<PatientProgram>> createProgram({
    required String patientId,
    required List<String> conditionIds,
    String? examination,
    String? imagingNotes,
    String? exaggeratingPositions,
    String? relievingPositions,
    String? notes,
    List<ProgramAttachment>? pendingAttachments,
    TreatmentPlanInput? treatmentPlan,
  }) async {
    final paths = <String>[];
    try {
      List<Map<String, dynamic>>? docPayloads;
      if (pendingAttachments != null && pendingAttachments.isNotEmpty) {
        final res = await ProgramStorageHelper.uploadAttachments(
          service: _service,
          patientId: patientId,
          attachments: pendingAttachments,
        );
        docPayloads = res.payloads;
        paths.addAll(res.paths);
      }

      final params = <String, dynamic>{
        'p_patient_id': patientId,
        'p_condition_ids': conditionIds,
        'p_examination': examination,
        'p_imaging_notes': imagingNotes,
        'p_exaggerating_positions': exaggeratingPositions,
        'p_relieving_positions': relievingPositions,
        'p_notes': notes,
        if (docPayloads != null) 'p_documents': docPayloads,
        if (treatmentPlan != null && treatmentPlan.isNotEmpty)
          'p_treatment_plan': treatmentPlan.toJson(),
      };

      final data = await _service.guardQuery(
        () => _service.rpc<Map<String, dynamic>>(
          'create_patient_program',
          params: params,
        ),
      );

      final programId = data['id'] as String;
      final fullResult = await getProgramById(programId);

      return fullResult.when(
        success: (program) => Result.success(program!),
        failure: (exception) => Result.failure(exception),
      );
    } catch (error) {
      await ProgramStorageHelper.cleanupPaths(service: _service, paths: paths);
      return Result.failure(
        error is AppException
            ? error
            : AppException.fromSupabaseException(
                error is Exception ? error : Exception(error.toString()),
              ),
      );
    }
  }

  @override
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
    TreatmentPlanInput? treatmentPlan,
  }) async {
    final paths = <String>[];
    try {
      List<Map<String, dynamic>>? docPayloads;
      if (pendingAttachments != null && pendingAttachments.isNotEmpty) {
        final res = await ProgramStorageHelper.uploadAttachments(
          service: _service,
          patientId: patientId,
          attachments: pendingAttachments,
        );
        docPayloads = res.payloads;
        paths.addAll(res.paths);
      }

      final params = <String, dynamic>{
        'p_program_id': programId,
        'p_condition_ids': conditionIds,
        'p_examination': examination,
        'p_imaging_notes': imagingNotes,
        'p_exaggerating_positions': exaggeratingPositions,
        'p_relieving_positions': relievingPositions,
        'p_notes': notes,
        if (status != null) 'p_status': status.name,
        if (docPayloads != null) 'p_documents': docPayloads,
        if (treatmentPlan != null && treatmentPlan.isNotEmpty)
          'p_treatment_plan': treatmentPlan.toJson(),
      };

      await _service.guardQuery(
        () => _service.rpc<Map<String, dynamic>>(
          'update_patient_program',
          params: params,
        ),
      );

      final fullResult = await getProgramById(programId);
      return fullResult.when(
        success: (program) => Result.success(program!),
        failure: (exception) => Result.failure(exception),
      );
    } catch (error) {
      await ProgramStorageHelper.cleanupPaths(service: _service, paths: paths);
      return Result.failure(
        error is AppException
            ? error
            : AppException.fromSupabaseException(
                error is Exception ? error : Exception(error.toString()),
              ),
      );
    }
  }

  @override
  Future<Result<void>> updateProgramStatus({
    required String programId,
    required ProgramStatus status,
  }) async {
    try {
      await _service.guardQuery(
        () => _service.from(_tableName).update({
          'status': status.name,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', programId),
      );
      return const Result.success(null);
    } on Exception catch (error) {
      return Result.failure(
        error is AppException ? error : AppException.fromSupabaseException(error),
      );
    }
  }

  @override
  Future<Result<void>> deleteProgram(String programId) async {
    try {
      final docRows = await _service.guardQuery(
        () => _service.from('patient_documents').select('file_url').eq('program_id', programId),
      ) as List<dynamic>;

      final paths = docRows
          .map((r) => patientDocumentStoragePath((r as Map<String, dynamic>)['file_url'] as String?))
          .whereType<String>()
          .toList();

      await _service.guardQuery(
        () => _service.from(_tableName).delete().eq('id', programId),
      );

      if (paths.isNotEmpty) {
        await ProgramStorageHelper.cleanupPaths(service: _service, paths: paths);
      }

      return const Result.success(null);
    } on Exception catch (error) {
      return Result.failure(
        error is AppException ? error : AppException.fromSupabaseException(error),
      );
    }
  }
}
