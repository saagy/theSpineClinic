import 'package:spine_clinic_app/core/errors/result.dart';

/// One hand correction of a patient's session balances
/// (`patient_balance_adjustments`). Rows are never edited.
class BalanceAdjustment {
  const BalanceAdjustment({
    required this.ptBefore,
    required this.ptAfter,
    required this.tractionBefore,
    required this.tractionAfter,
    required this.reason,
    required this.adjustedByName,
    required this.adjustedAt,
  });

  factory BalanceAdjustment.fromJson(Map<String, dynamic> json) => BalanceAdjustment(
    ptBefore: (json['pt_before'] as num).toInt(),
    ptAfter: (json['pt_after'] as num).toInt(),
    tractionBefore: (json['traction_before'] as num).toInt(),
    tractionAfter: (json['traction_after'] as num).toInt(),
    reason: json['reason'] as String,
    adjustedByName: json['adjusted_by_name'] as String,
    adjustedAt: DateTime.parse(json['adjusted_at'] as String),
  );

  final int ptBefore;
  final int ptAfter;
  final int tractionBefore;
  final int tractionAfter;
  final String reason;
  final String adjustedByName;
  final DateTime adjustedAt;

  bool get changesPt => ptBefore != ptAfter;
  bool get changesTraction => tractionBefore != tractionAfter;
}

/// Corrections of session balances by payment staff.
abstract interface class BalanceAdjustmentRepository {
  /// Newest first.
  Future<Result<List<BalanceAdjustment>>> getAdjustments(String patientId);

  /// Sets both balances. [expectedPt] and [expectedTraction] are the
  /// balances the person saw; the database refuses the change
  /// (`balance_changed`) if either has moved since.
  Future<Result<void>> adjust({
    required String patientId,
    required int expectedPt,
    required int expectedTraction,
    required int pt,
    required int traction,
    required String reason,
  });
}
