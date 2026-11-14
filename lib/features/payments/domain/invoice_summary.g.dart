// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InvoiceSummary _$InvoiceSummaryFromJson(Map<String, dynamic> json) =>
    _InvoiceSummary(
      id: json['id'] as String,
      branch: $enumDecode(_$ClinicLocationEnumMap, json['branch']),
      number: (json['number'] as num).toInt(),
      patientId: json['patient_id'] as String,
      invoiceDate: DateTime.parse(json['invoice_date'] as String),
      totalMinor: (json['total_minor'] as num).toInt(),
      discountMinor: (json['discount_minor'] as num).toInt(),
      valueMinor: (json['value_minor'] as num).toInt(),
      collectedMinor: (json['net_collected_minor'] as num).toInt(),
      dueMinor: (json['due_minor'] as num).toInt(),
      refundedMinor: (json['refunded_minor'] as num).toInt(),
      status: _statusFromJson(json['status'] as String),
      services: json['services'] as String? ?? '',
      doctors: json['doctors'] == null
          ? const []
          : _doctorsFromJson(json['doctors']),
      createdAt: DateTime.parse(json['created_at'] as String),
      createdByName: json['created_by_name'] as String,
      version: (json['version'] as num).toInt(),
    );

Map<String, dynamic> _$InvoiceSummaryToJson(_InvoiceSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'branch': _$ClinicLocationEnumMap[instance.branch]!,
      'number': instance.number,
      'patient_id': instance.patientId,
      'invoice_date': instance.invoiceDate.toIso8601String(),
      'total_minor': instance.totalMinor,
      'discount_minor': instance.discountMinor,
      'value_minor': instance.valueMinor,
      'net_collected_minor': instance.collectedMinor,
      'due_minor': instance.dueMinor,
      'refunded_minor': instance.refundedMinor,
      'status': _statusToJson(instance.status),
      'services': instance.services,
      'doctors': instance.doctors,
      'created_at': instance.createdAt.toIso8601String(),
      'created_by_name': instance.createdByName,
      'version': instance.version,
    };

const _$ClinicLocationEnumMap = {
  ClinicLocation.tagamoa: 'tagamoa',
  ClinicLocation.masrElgedida: 'masr_elgedida',
  ClinicLocation.madinaty: 'madinaty',
};
