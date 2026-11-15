import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/patient/domain/balance_adjustment.dart';

/// Supabase-backed [BalanceAdjustmentRepository]. Writes go through the
/// `adjust_patient_balance` RPC, which records each change atomically.
class BalanceAdjustmentRepositoryImpl implements BalanceAdjustmentRepository {
  BalanceAdjustmentRepositoryImpl({required SupabaseService supabaseService})
    : _service = supabaseService;

  final SupabaseService _service;

  Future<Result<T>> _run<T>(Future<T> Function() action) async {
    try {
      return Result.success(await _service.guardQuery(action));
    } on AppException catch (error) {
      return Result.failure(error);
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }

  @override
  Future<Result<List<BalanceAdjustment>>> getAdjustments(String patientId) => _run(() async {
    final List<Map<String, dynamic>> rows = await _service
        .from('patient_balance_adjustments')
        .select('pt_before, pt_after, traction_before, traction_after, reason, adjusted_by_name, adjusted_at')
        .eq('patient_id', patientId)
        .order('adjusted_at', ascending: false);
    return rows.map(BalanceAdjustment.fromJson).toList();
  });

  @override
  Future<Result<void>> adjust({
    required String patientId,
    required int expectedPt,
    required int expectedTraction,
    required int pt,
    required int traction,
    required String reason,
  }) => _run(
    () => _service.rpc<void>(
      'adjust_patient_balance',
      params: <String, dynamic>{
        'p_patient_id': patientId,
        'p_expected_pt': expectedPt,
        'p_expected_traction': expectedTraction,
        'p_pt': pt,
        'p_traction': traction,
        'p_reason': reason.trim(),
      },
    ),
  );
}
