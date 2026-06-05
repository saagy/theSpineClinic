/// Freezed model for the `public.payment_records` table.
///
/// Maps 1:1 to the Supabase schema (AGENT_CONTEXT §3).
/// Rule 4 — repositories wrap this in `Result<T>`.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_record.freezed.dart';
part 'payment_record.g.dart';

double _amountFromJson(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? 0.0;
  }
  return 0.0;
}

Object _amountToJson(double value) => value;

/// A payment record in the Spine Clinic system.
@freezed
abstract class PaymentRecord with _$PaymentRecord {
  /// Creates a [PaymentRecord].
  const factory PaymentRecord({
    required String id,
    @JsonKey(name: 'patient_id') required String patientId,
    @JsonKey(fromJson: _amountFromJson, toJson: _amountToJson) required double amount,
    required String reason,
    @JsonKey(name: 'recorded_by') String? recordedBy,
    @JsonKey(name: 'recorded_at') required DateTime recordedAt,
  }) = _PaymentRecord;

  /// Deserialises from a Supabase JSON row.
  factory PaymentRecord.fromJson(Map<String, dynamic> json) =>
      _$PaymentRecordFromJson(json);
}
