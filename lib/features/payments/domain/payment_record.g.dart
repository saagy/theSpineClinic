// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PaymentRecord _$PaymentRecordFromJson(
  Map<String, dynamic> json,
) => _PaymentRecord(
  id: json['id'] as String,
  patientId: json['patient_id'] as String,
  amount: _amountFromJson(json['amount']),
  reason: json['reason'] as String,
  recordedBy: json['recorded_by'] as String?,
  recordedAt: DateTime.parse(json['recorded_at'] as String),
  sessionBalanceAdded: (json['session_balance_added'] as num?)?.toInt() ?? 0,
  tractionBalanceAdded: (json['traction_balance_added'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$PaymentRecordToJson(_PaymentRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'patient_id': instance.patientId,
      'amount': _amountToJson(instance.amount),
      'reason': instance.reason,
      'recorded_by': instance.recordedBy,
      'recorded_at': instance.recordedAt.toIso8601String(),
      'session_balance_added': instance.sessionBalanceAdded,
      'traction_balance_added': instance.tractionBalanceAdded,
    };
