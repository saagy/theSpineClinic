import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/admin/data/analytics_dtos.dart';

/// Repository contract for analytics queries.
///
/// Each method covers one independent section of the analytics dashboard.
/// Consumers call these in parallel so sections load and error independently.
abstract class AnalyticsRepository {
  /// Financial metrics: revenue, payment types, outstanding balances, packages.
  Future<Result<FinancialSummary>> getFinancialSummary({
    required DateTimeRange range,
    String? branchId,
  });

  /// Appointment metrics: volume, completion/cancellation rates, by-status,
  /// by-day-of-week breakdowns.
  Future<Result<AppointmentSummary>> getAppointmentSummary({
    required DateTimeRange range,
    String? branchId,
  });

  /// Staff metrics: appointments per doctor, completion rates, top performers,
  /// new hires in period.
  Future<Result<StaffSummary>> getStaffSummary({
    required DateTimeRange range,
  });

  /// Patient metrics: registrations, active count, branch distribution,
  /// returning vs new ratio.
  Future<Result<PatientSummary>> getPatientSummary({
    required DateTimeRange range,
    String? branchId,
  });
}
