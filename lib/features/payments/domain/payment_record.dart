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

double? _nullableAmountFromJson(Object? value) {
  if (value == null) return null;
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

Object? _nullableAmountToJson(double? value) => value;

/// A payment record in the Spine Clinic system.
@freezed
abstract class PaymentRecord with _$PaymentRecord {
  /// Constructor required to add custom getters / methods to a Freezed class.
  const PaymentRecord._();

  /// Creates a [PaymentRecord].
  const factory PaymentRecord({
    required String id,
    @JsonKey(name: 'patient_id') required String patientId,
    @JsonKey(fromJson: _amountFromJson, toJson: _amountToJson) required double amount,
    required String reason,
    @JsonKey(name: 'recorded_by') String? recordedBy,
    @JsonKey(name: 'recorded_at') required DateTime recordedAt,

    /// Number of Normal PT sessions added to patient balance by this payment.
    @JsonKey(name: 'session_balance_added') @Default(0) int sessionBalanceAdded,

    /// Number of Spinal Traction sessions added to patient balance by this payment.
    @JsonKey(name: 'traction_balance_added') @Default(0) int tractionBalanceAdded,

    /// Full price of the service (null = paid in full, meaning total_price is equal to amount).
    @JsonKey(name: 'total_price', fromJson: _nullableAmountFromJson, toJson: _nullableAmountToJson) double? totalPrice,
  }) = _PaymentRecord;

  /// Computed helper for outstanding due.
  double get remainingDue =>
      (totalPrice != null && totalPrice! > amount) ? totalPrice! - amount : 0.0;

  /// Whether this payment has any outstanding due balance.
  bool get hasOutstandingDue => remainingDue > 0.0;

  /// Deserialises from a Supabase JSON row.
  factory PaymentRecord.fromJson(Map<String, dynamic> json) =>
      _$PaymentRecordFromJson(json);
}
