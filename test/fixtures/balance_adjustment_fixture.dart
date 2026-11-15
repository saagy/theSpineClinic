import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/patient/domain/balance_adjustment.dart';

/// Balance corrections for the workspace fixture: one earlier correction,
/// and every save recorded in [calls].
class FakeBalanceAdjustmentRepository implements BalanceAdjustmentRepository {
  FakeBalanceAdjustmentRepository({this.empty = false});
  final bool empty;
  final List<Map<String, Object>> calls = [];

  @override
  Future<Result<List<BalanceAdjustment>>> getAdjustments(String patientId) async => Result.success(
    empty
        ? const []
        : [
            BalanceAdjustment(
              ptBefore: 0,
              ptAfter: 4,
              tractionBefore: 0,
              tractionAfter: 2,
              reason: 'Carried over from the paper file',
              adjustedByName: 'Salma Mostafa',
              adjustedAt: DateTime(2026, 11, 2, 10),
            ),
          ],
  );

  @override
  Future<Result<void>> adjust({
    required String patientId,
    required int expectedPt,
    required int expectedTraction,
    required int pt,
    required int traction,
    required String reason,
  }) async {
    calls.add({
      'expected': [expectedPt, expectedTraction],
      'new': [pt, traction],
      'reason': reason,
    });
    return const Result.success(null);
  }
}
