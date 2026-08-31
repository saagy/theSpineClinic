library;

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_input.dart';
import 'package:spine_clinic_app/features/medical_records/domain/treatment_plan.dart';
import 'package:spine_clinic_app/features/medical_records/domain/treatment_plan_repository.dart';

/// Supabase Postgres implementation of [TreatmentPlanRepository].
class TreatmentPlanRepositoryImpl implements TreatmentPlanRepository {
  TreatmentPlanRepositoryImpl({required SupabaseService supabaseService})
      : _service = supabaseService;

  final SupabaseService _service;
  static const String _tableName = 'treatment_plans';
  static const String _selectQuery = '''
    *,
    plan_modalities(
      *,
      modality_regions(*)
    )
  ''';

  @override
  Future<Result<TreatmentPlan>> upsertPlan({
    required String programId,
    String? planId,
    required String planName,
    required bool isActive,
    String? notes,
    required List<ModalityInput> modalities,
  }) async {
    try {
      final params = <String, dynamic>{
        'p_program_id': programId,
        if (planId != null) 'p_plan_id': planId,
        'p_plan_name': planName.trim().isEmpty ? 'Plan 1' : planName.trim(),
        'p_is_active': isActive,
        'p_notes': notes?.trim().isEmpty ?? true ? null : notes?.trim(),
        'p_modalities': modalities.map((m) => m.toJson()).toList(),
      };

      final data = await _service.guardQuery(
        () => _service.rpc<Map<String, dynamic>>(
          'upsert_treatment_plan',
          params: params,
        ),
      );

      final String resolvedPlanId = (data['id'] as String?) ?? planId!;

      final planData = await _service.guardQuery(
        () => _service
            .from(_tableName)
            .select(_selectQuery)
            .eq('id', resolvedPlanId)
            .single(),
      );

      final plan = TreatmentPlan.fromJson(planData);
      return Result.success(plan);
    } catch (error) {
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
  Future<Result<void>> activatePlan({
    required String planId,
    required String programId,
  }) async {
    try {
      await _service.guardQuery(
        () => _service.rpc<bool>(
          'activate_treatment_plan',
          params: {
            'p_plan_id': planId,
            'p_program_id': programId,
          },
        ),
      );
      return const Result.success(null);
    } catch (error) {
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
  Future<Result<void>> deletePlan(String planId) async {
    try {
      await _service.guardQuery(
        () => _service.rpc<bool>(
          'delete_treatment_plan',
          params: {'p_plan_id': planId},
        ),
      );
      return const Result.success(null);
    } catch (error) {
      return Result.failure(
        error is AppException
            ? error
            : AppException.fromSupabaseException(
                error is Exception ? error : Exception(error.toString()),
              ),
      );
    }
  }
}
