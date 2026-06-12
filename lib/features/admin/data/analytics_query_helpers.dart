import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';

/// Shared query helpers used by [AnalyticsRepositoryImpl].
/// Extracted to keep the main implementation file under 200 lines.

const List<String> dayLabels = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday',
  'Friday', 'Saturday', 'Sunday',
];

Future<List<Map<String, dynamic>>> fetchPayments(
  SupabaseService svc,
  DateTimeRange range,
  String? branchId,
) async {
  return svc.guardQuery(() {
    var q = svc
        .from('payment_records')
        .select('amount, reason, recorded_at, patient:patients!inner(clinic)')
        .gte('recorded_at', range.start.toIso8601String())
        .lte('recorded_at', range.end.toIso8601String());
    if (branchId != null) q = q.eq('patient.clinic', branchId);
    return q;
  });
}

Future<List<Map<String, dynamic>>> fetchAppointments(
  SupabaseService svc,
  DateTimeRange range,
  String? branchId,
) async {
  return svc.guardQuery(() {
    var q = svc
        .from('appointments')
        .select('id, status, scheduled_at, patient:patients!inner(clinic)')
        .gte('scheduled_at', range.start.toIso8601String())
        .lte('scheduled_at', range.end.toIso8601String());
    if (branchId != null) q = q.eq('patient.clinic', branchId);
    return q;
  });
}

String paymentCategory(String reason) {
  if (reason.contains('package')) return 'package';
  if (reason.contains('session')) return 'session';
  if (reason.contains('gehaz') || reason.contains('traction')) return 'gehaz';
  return 'other';
}

String extractClinic(dynamic patientField) {
  if (patientField is Map<String, dynamic>) {
    return patientField['clinic'] as String? ?? 'unknown';
  }
  return 'unknown';
}
